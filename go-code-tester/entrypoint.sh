#!/bin/bash

# Copyright (c) 2020-2024 Dell Inc., or its subsidiaries. All Rights Reserved.
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

if [[ -n $SKIP_TEST ]]; then
  echo "skipping the following tests (regex): $SKIP_TEST"
  skip_options="-skip $SKIP_TEST"
fi

if [[ -n $RUN_TEST ]]; then
  echo "running the following tests (regex): $RUN_TEST"
  run_options="-run $RUN_TEST"
fi

go clean -testcache

cd ${TEST_FOLDER}
if [[ -n $EXCLUDE_DIRECTORIES ]]; then
  echo "excluding the following directories: $EXCLUDE_DIRECTORIES"
  if [[ -z $RACE_DETECTOR ]] || [[ $RACE_DETECTOR == "true" ]]; then
    echo ${TEST_FOLDER}
    echo $EXCLUDE_DIRECTORIES
    ex=$(echo $EXCLUDE_DIRECTORIES && go list ./... | grep -vE "$EXCLUDE_DIRECTORIES")
    echo "$ex"
    GOEXPERIMENT=nocoverageredesign go test $skip_options -v $(go list ./... | grep -vE "$EXCLUDE_DIRECTORIES") -short -race -count=1 -cover $run_options > ~/run.log
  else
    # Run without the race flag
    GOEXPERIMENT=nocoverageredesign go test $skip_options -v $(go list ./... | grep -vE $EXCLUDE_DIRECTORIES) -short -count=1 -cover $run_options > ~/run.log
  fi
else
  GOEXPERIMENT=nocoverageredesign go test $skip_options -v -short -count=1 -cover $run_options > ~/run.log
fi

TEST_RETURN_CODE=$?
cat ~/run.log
if [ "${TEST_RETURN_CODE}" != "0" ]; then
  echo "test failed with return code $TEST_RETURN_CODE, not proceeding with coverage check"
  exit 1
fi

if [ -z "$SKIP_LIST" ]
then
  echo "No packages in skip-list"
else
  # Put skip list in grep-friendly and human-friendly formats
  SKIP_LIST_FOR_GREP=${SKIP_LIST//[,]/ -e }
  SKIP_LIST_FOR_ECHO=${SKIP_LIST//[,]/, }
  echo "skipping the following packages: $SKIP_LIST_FOR_ECHO"
fi

FAIL=0
check_coverage() {
  pkg=$1
  cov=$2
  if [[ ${THRESHOLD} -gt ${cov%.*} ]]; then
     echo "FAIL: coverage for package $pkg is ${cov}%, lower than ${THRESHOLD}%"
     FAIL=1
  else
     echo "PASS: coverage for package $pkg is ${cov}%, not lower than ${THRESHOLD}%"
  fi

  return 0
}

if [ -z "$SKIP_LIST" ]; then
  # If there is no skip-list, just search for cases where the word coverage is preceded by whitespace. We want the space because
  # this distinguishes between the final coverage report and the intermediate coverage printouts that happen earlier in the output
  while read pkg cov;
  do
    check_coverage $pkg $cov
  done <<< $(cat ~/run.log | grep ^ok | awk '{print $2, substr($5, 1, length($5)-1)}')
else
  # this is the same as the above, except it includes a filter that gets rid of all the packages that appear in the skip-list
  while read pkg cov;
  do
    check_coverage $pkg $cov
  done <<< $(cat ~/run.log | grep ^ok | grep -vw -e $SKIP_LIST_FOR_GREP | awk '{print $2, substr($5, 1, length($5)-1)}')
fi

exit ${FAIL}
