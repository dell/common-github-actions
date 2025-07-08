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

if [ -n "$EXCLUDES" ]
then
  EXCLUDE_FLAG="-exclude=$EXCLUDES"
fi

EXCLUDE_DIR_FLAG=""

get_exclude_directories() {
    # Retrieves the submodules that should be excluded from current directory
    submodules=$(find . -name 'go.mod' -exec dirname {} +)

    exclude_arg=""

    for submodule in $submodules; do
        if [ "$submodule" == "." ]; then
            continue
        fi

        # Remove leading './'
        sub=$(echo "$submodule" | sed 's/\.\///')
        
        exclude_arg="$exclude_arg -exclude-dir=$sub"
    done

    # Set the global variable
    EXCLUDE_DIR_FLAG="$exclude_arg"
}

submodules=$(find . -name 'go.mod' -exec dirname {} +)
for submodule in $submodules; do
  echo "Running gosec on $submodule"
  cd "$submodule"

  get_exclude_directories "$submodule"

  echo "run gosec command: $(go env GOPATH)/bin/gosec -exclude-generated $EXCLUDE_FLAG $EXCLUDE_DIR_FLAG $DIRECTORIES"
  $(go env GOPATH)/bin/gosec -exclude-generated $EXCLUDE_FLAG $EXCLUDE_DIR_FLAG $DIRECTORIES

  TEST_RETURN_CODE=$?
  if [ "${TEST_RETURN_CODE}" != "0" ]; then
    echo "Gosec failed with return code $TEST_RETURN_CODE"
    exit 1
  fi

  # Reset the global variable
  EXCLUDE_DIR_FLAG=""

  # Pop back to the parent directory
  cd - > /dev/null
done

echo "Gosec ran successfully!"
exit 0
