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
EXCLUDE_DIR=$3

if [ -n "$EXCLUDES" ]
then
  EXCLUDE_FLAG="-exclude=$EXCLUDES"
fi

if [ -n "$EXCLUDE_DIR" ]
then
  EXCLUDE_DIR_FLAG="-exclude-dir=$EXCLUDE_DIR"
fi

# Fetch the latest version of gosec
LATEST_VERSION=$(curl -s https://api.github.com/repos/securego/gosec/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s -- -b $(go env GOPATH)/bin $LATEST_VERSION

# Find all directories containing go.mod files
if [ -n "$EXCLUDE_DIR" ]; then
  EXCLUDED_PATHS=$(echo "$EXCLUDE_DIR" | sed 's/|/\/\*\" -not -path \"/g' | sed 's/^/-not -path \"/' | sed 's/$/\/\*\"/')
  submodules=$(eval find . -name 'go.mod' "$EXCLUDED_PATHS" -exec dirname {} +)
else
  submodules=$(find . -name 'go.mod' -exec dirname {} +)
fi

for submodule in $submodules; do
  echo "Running gosec on $submodule"
  cd "$submodule"

  echo "run gosec command: $(go env GOPATH)/bin/gosec -exclude-generated $EXCLUDE_FLAG $EXCLUDE_DIR_FLAG $DIRECTORIES"
  $(go env GOPATH)/bin/gosec -exclude-generated $EXCLUDE_FLAG $EXCLUDE_DIR_FLAG $DIRECTORIES

  TEST_RETURN_CODE=$?
  if [ "${TEST_RETURN_CODE}" != "0" ]; then
    echo "Gosec failed with return code $TEST_RETURN_CODE"
    exit 1
  fi

  # Pop back to the parent directory
  cd - > /dev/null
done

echo "Gosec ran successfully!"
exit 0
