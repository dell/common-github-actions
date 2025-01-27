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

cd ${TEST_FOLDER}

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
    FAIL=1
  else
    echo "PASS: coverage for package $pkg is ${cov}%, not lower than ${THRESHOLD}%"
  fi

  return 0
}

# Find all directories containing go.mod files
submodules=$(find . -name 'go.mod' -exec dirname {} \;)

for submodule in $submodules; do
  echo "Running coverage for submodule: $submodule"
  cd "$submodule"

  # Get the list of packages
  if [[ -n $EXCLUDE_DIRECTORIES ]]; then
    echo "excluding the following directories: $EXCLUDE_DIRECTORIES"
    packages=$(go list ./... | grep -vE $EXCLUDE_DIRECTORIES)
  else
    packages=$(go list ./...)
  fi

  for package in $packages; do
    # Skip packages in the skip list
    if [[ -n "$SKIP_LIST" && $SKIP_LIST =~ $package ]]; then
      echo "Skipping package $package"
      continue
    fi

    # Run go test with coverage for the package
    if [[ -z $RACE_DETECTOR ]] || [[ $RACE_DETECTOR == "true" ]]; then
      # Run with the race flag
      output=$(go test $skip_options -v -short -race -count=1 -cover $package $run_options 2>&1)
      TEST_RETURN_CODE=$?
    else
      # Run without the race flag
      output=$(go test $skip_options -v -short -count=1 -cover $package $run_options 2>&1)
      TEST_RETURN_CODE=$?
    fi

    echo "$output"

    if [ "${TEST_RETURN_CODE}" != "0" ]; then
      echo "test failed for package $package with return code $TEST_RETURN_CODE, not proceeding with coverage check"
      FAIL=1
    fi

    # Extract coverage percentage
    coverage=$(echo "$output" | grep -oP 'coverage: \d+\.\d+%' | grep -oP '\d+\.\d+')

    # Handle packages with no test files or 0% coverage
    if [[ -z $coverage ]]; then
        coverage=0
    fi

    coverage_results["$package"]=$coverage
  done

  cd - > /dev/null
done

# Check if coverage meets the minimum threshold
echo "Coverage results:"
for pkg in "${!coverage_results[@]}"; do
  check_coverage $pkg ${coverage_results[$pkg]} | tee -a coverage_results.txt
  if [[ $? -ne 0 ]]; then
    FAIL=1
  fi
done

# Escape newlines and special characters before writing to $GITHUB_OUTPUT
escaped_coverage=$(cat coverage_results.txt | awk '{printf "%s\\n", $0}')
echo "coverage=$escaped_coverage" >> $GITHUB_OUTPUT

exit ${FAIL}
