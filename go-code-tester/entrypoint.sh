#!/bin/bash

# Copyright (c) 2020 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

THRESHOLD=$1
SKIP_LIST=$2
pkg_skip_list=

# Second parameter is a comma delimited list of
# Go package names that should have the coverage
# criteria applied against


go clean -testcache

TEST_OUTPUT=$(cd service;go test -v -short -count=1 -race -cover ./...)
TEST_RETURN_CODE=$?

if [ "${TEST_RETURN_CODE}" != "0" ]; then
    exit 1
fi
