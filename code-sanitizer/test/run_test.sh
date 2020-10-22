#!/bin/bash

total_tests=0
failed_tests=0
passed_tests=0

function run_script() {
  name=$1
  directory=$2
  expected=$3
  message=$4

  total_test=$((total_tests + 1))

  bash entrypoint.sh -d "test/$directory"
  actual=$?

  if [ "${expected}" -eq ${actual} ]; then
    echo "[${name}] - Passed"
    passed_tests=$((passed_tests + 1))
  else
    echo "[${name}] - Failed : ${message}, ${actual}"
    failed_tests=$((failed_tests + 1))
  fi
}

run_script "Clean run" clean 0 "Expected no non-inclusive language, but found"
run_script "Found some" non-inclusive 50 "Expected to find 50"

echo "Total tests ${total_test} Passed: ${passed_tests} Failed: ${failed_tests}"

exit $failed_tests
