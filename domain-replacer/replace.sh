#!/bin/bash

# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

set -e

echo "Scanning for files to update..."

find . -type f ! -name "go.sum" | while read -r file; do
  echo "Checking $file"
  if grep -q 'github.com/dell/' "$file"; then
    echo "Updating $file"
    sed -i 's|github.com/dell/|eos2git.cec.lab.emc.com/CSM/|g' "$file"
  fi
done