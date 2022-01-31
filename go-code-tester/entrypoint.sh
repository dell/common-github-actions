#!/bin/bash

# Copyright (c) 2020 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

THRESHOLD=$1
TEST_FOLDER=$2
SKIP_LIST=$3
pkg_skip_list=

go clean -testcache

cd ${TEST_FOLDER}
pwd
go test -v -short -race -count=1 -cover ./... > run.log
TEST_RETURN_CODE=$?
cat run.log
if [ "${TEST_RETURN_CODE}" != "0" ]; then
  echo "test failed with return code $TEST_RETURN_CODE"
  exit 1
fi

# Put skip list in format that will work for grep and into format that is human-readable
SKIP_LIST_FOR_GREP=${SKIP_LIST//[,]/ -e }
SKIP_LIST_FOR_ECHO=${SKIP_LIST//[,]/, }

echo "skipping the following packages: $SKIP_LIST_FOR_ECHO"

FAIL=0
check_coverage() {
  pkg=$1
  cov=$2
  if [[ ${THRESHOLD} > ${cov%.*} ]]; then
     echo "FAIL: coverage for package $pkg is ${cov}%, lower than 90%"
     FAIL=1
  else
     echo "PASS: coverage for package $pkg is ${cov}%, greater than 90%"
  fi

  return 0
}

if [ -z "$SKIP_LIST_FOR_GREP" ]; then
  # If there is no skip-list, just search for cases where the word coverage is preceded by whitespace. We want the space because
  # this distinguishes between the final coverage report and the intermediate coverage printouts that happen earlier in the output
  cat ~/run.log | grep -e "\scoverage" | awk '{print $2, substr($5, 1, length($5)-1)}' | while read pkg cov;
  do
    check_coverage $pkg $cov
  done
else
  # this is the same as the above, except it includes a filter that gets rid of all the packages that appear in the skip-list
  cat ~/run.log | grep -e "\scoverage" | grep -vw -e $SKIP_LIST_FOR_GREP | awk '{print $2, substr($5, 1, length($5)-1)}' | while read pkg cov;
  do
    check_coverage $pkg $cov
  done
fi

exit ${FAIL}

