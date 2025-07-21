#!/bin/bash
set -e

echo "Scanning for files to update..."

# Ensure REPLACEMENT_DOMAIN is set
if [ -z "$REPLACEMENT_DOMAIN" ]; then
  echo "Error: REPLACEMENT_DOMAIN environment variable is not set."
  exit 1
fi

find . -type f ! -name "go.sum" | while read -r file; do
  echo "Checking $file"
  if grep -q 'github.com/dell/' "$file"; then
    echo "Updating $file"
    sed -i "s|github.com/dell/|$REPLACEMENT_DOMAIN|g" "$file"
  fi
done
