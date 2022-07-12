#!/bin/bash

# Copyright (c) 2020 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

DIRECTORIES=$1
EXCLUDES=$2

GOFLAGS=$GOFLAGS" -buildvcs=false"
echo "GOFLAGS: $GOFLAGS"

apt update -y
apt install snapd -y
snap install gosec

gosec -exclude=G304 ./...

TEST_RETURN_CODE=$?
if [ "${TEST_RETURN_CODE}" != "0" ]; then
  echo "test failed with return code $TEST_RETURN_CODE"
  exit 1
fi

exit 0
