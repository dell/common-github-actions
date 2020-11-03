#!/bin/bash

# Copyright (c) 2020 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

THRESHOLD=$1

go clean -testcache

TEST_OUTPUT=$(go test -short -count=1 -race -cover ./... | tee /dev/stderr; exit ${PIPESTATUS[0]})
TEST_RETURN_CODE=$?

if [ "${TEST_RETURN_CODE}" != "0" ]; then
    exit 1
fi

COVERAGE_TMPFILE=/tmp/check_coverage
COVERAGE_TMPFILE_COUNT=${COVERAGE_TMPFILE}.count
touch ${COVERAGE_TMPFILE}.count

check_coverage() {
    while read -r line
    do
        no_tests=$(echo "$line" | awk '{print $1}')
        if [ "$no_tests" == "?" ]; then
            continue
        fi
        echo "$line" | awk '{print $2, substr($5, 1, length($5)-1)}' | while read pkg cov
        do
            if [ $((${cov%.*} - ${THRESHOLD})) -lt 0 ]; then
                echo "$pkg" does not meet "$THRESHOLD"% coverage | tee $COVERAGE_TMPFILE
                cat $COVERAGE_TMPFILE | wc -l > $COVERAGE_TMPFILE_COUNT
            fi 
        done
    done <<< "${TEST_OUTPUT}"

    if [ ! -z `cat $COVERAGE_TMPFILE_COUNT` ] && [ ! `cat $COVERAGE_TMPFILE_COUNT` -eq "0" ]; then
        return 1
    fi
    return 0
}

check_coverage
CHECK_COVERAGE_RETURN_CODE=$?
exit ${CHECK_COVERAGE_RETURN_CODE}
