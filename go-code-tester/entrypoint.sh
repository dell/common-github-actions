#!/bin/bash

# Copyright (c) 2020-2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

THRESHOLD=$1
TEST_FOLDER=$2
SKIP_LIST=$3
RACE_DETECTOR=$4
SKIP_TEST=$5
RUN_TEST=$6
EXCLUDE_DIRECTORIES=$7

skip_options=""
run_options=""

declare -A coverage_results
declare -a failed_packages

# Skip packages in the skip list
if [ -z "$SKIP_LIST" ]; then
  echo "No packages in skip-list"
else
  # Put skip list in human-friendly formats
  SKIP_LIST_FOR_ECHO=${SKIP_LIST//[,]/, }
  echo "Skipping the following packages: $SKIP_LIST_FOR_ECHO"
fi

if [[ -n $SKIP_TEST ]]; then
  echo "skipping the following tests (regex): $SKIP_TEST"
  skip_options="-skip $SKIP_TEST"
fi

if [[ -n $RUN_TEST ]]; then
  echo "running the following tests (regex): $RUN_TEST"
  run_options="-run $RUN_TEST"
fi

go env -w GOFLAGS=-buildvcs=false
go clean -testcache

if [[ -n $TEST_FOLDER ]]; then
  cd ${TEST_FOLDER}
fi

FAIL=0
check_coverage() {
  pkg=$1
  cov=$2

  # Check if coverage is [no statements]
  if [[ "$cov" == "[n" ]]; then
    echo "WARNING: coverage for package $pkg is not available: [no statements]"
    return 0
  # Check if coverage is a valid number
  elif ! [[ $cov =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "WARNING: coverage for package $pkg is not a valid threshold: $cov"
    return 0
  # Check if coverage is empty
  elif [[ -z "$cov" ]]; then
    echo "WARNING: coverage for package $pkg is not available"
    return 0
  elif [[ ${THRESHOLD} -gt ${cov%.*} ]]; then
    echo "FAIL: coverage for package $pkg is ${cov}%, lower than ${THRESHOLD}%"
    return 1
  else
    echo "PASS: coverage for package $pkg is ${cov}%, not lower than ${THRESHOLD}%"
    return 0
  fi
}

# Find all directories containing go.mod files
submodules=$(find . -name 'go.mod' -exec dirname {} \;)

# Submodules may not exist if testing in a specific TEST_FOLDER
if [[ -z "$submodules" ]]; then
  echo "No submodules found. Proceeding at $(pwd)"
  submodules="."
fi

for submodule in $submodules; do
  echo "Running coverage at $submodule"
  cd "$submodule"

  # Get the list of packages
  if [[ -n $EXCLUDE_DIRECTORIES ]]; then
    echo "Excluding the following directories: $EXCLUDE_DIRECTORIES"
    packages=$(go list ./... | grep -vE $EXCLUDE_DIRECTORIES)
  else
    packages=$(go list ./...)
  fi

  # Check go list for errors, including "go mod tidy" errors
  if [ $? -ne 0 ]; then
    echo "Please review failure in $submodule"
    FAIL=1
  fi

  for package in $packages; do
    # Run go test with coverage for the package
    if [[ -z $RACE_DETECTOR ]] || [[ $RACE_DETECTOR == "true" ]]; then
      # Run with the race flag
      go_test_cmd="go test $skip_options -v -short -race -count=1 -cover -coverprofile cover.out $package $run_options"
      output=$($go_test_cmd 2>&1)
      TEST_RETURN_CODE=$?

      # for debugging purposes
      echo "********** $go_test_cmd **********"
    else
      # Run without the race flag
      go_test_cmd="go test $skip_options -v -short -count=1 -cover -coverprofile cover.out $package $run_options"
      output=$($go_test_cmd 2>&1)
      TEST_RETURN_CODE=$?

      # for debugging purposes
      echo "********** $go_test_cmd **********"
    fi

    echo "$output"

    if [ "${TEST_RETURN_CODE}" != "0" ]; then
      echo "Test failed for package $package with return code $TEST_RETURN_CODE, not proceeding with coverage check"
      failed_packages+=("$package")
      FAIL=1
    fi

    # Extract coverage percentage
    coverage=$(echo "$output" | grep -oP 'coverage: \d+\.\d+%' | grep -oP '\d+\.\d+')

    # Handle packages with no test files or 0% coverage
    if [[ -z $coverage ]]; then
        coverage=0
    fi

    coverage_results["$package"]=$coverage

    # Append coverage results to combined file for "Generate coverage report" step
    cat cover.out >> coverage.txt
  done

  cd - > /dev/null
done

# Remove skipped packages from coverage_results, but the unit tests will still run
if [ -n "$SKIP_LIST" ]; then
  for pkg in ${SKIP_LIST//,/ }; do
    unset coverage_results["$pkg"]
  done
fi

# Report failed packages
if [ ${#failed_packages[@]} -ne 0 ]; then
  echo ""
  echo "The following packages failed unit tests and were not checked for coverage:"
  for pkg in "${failed_packages[@]}"; do
    echo "$pkg"
  done
  echo ""
fi

# Check if coverage meets the minimum threshold
echo "Coverage results:"
for pkg in "${!coverage_results[@]}"; do
  coverage_output=$(check_coverage $pkg ${coverage_results[$pkg]})
  RETURN_CODE=$?
  echo "$coverage_output"
  if [[ $RETURN_CODE -ne 0 ]]; then
    FAIL=1
  fi
  echo "$coverage_output" >> coverage_results.txt
done

# Escape newlines and special characters before writing to $GITHUB_OUTPUT
escaped_coverage=$(cat coverage_results.txt | awk '{printf "%s\\n", $0}')
echo "coverage=$escaped_coverage" >> $GITHUB_OUTPUT

# Below is for the "Upload coverprofile" and "Generate coverage report" steps
# --------------------------------------------------------------------------

# Process coverage.txt file to keep the first 'mode: atomic' and remove subsequent ones
awk 'NR==1 || $0 !~ /^mode: atomic$/' coverage.txt > new_coverage.txt
# Write to $GITHUB_OUTPUT
echo "code_coverage_artifact=new_coverage.txt" >> $GITHUB_OUTPUT

exit ${FAIL}
