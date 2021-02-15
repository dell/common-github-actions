#!/bin/bash

# Copyright (c) 2020 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

CHECK_DIRS=""
VET_IN_DIR=0
VET_DIR=""

captured_vet_dir=0
for param in "$@"
do
    case $param in
       "--vet-in-dir")
          VET_IN_DIR=1
          shift
          ;;
       *)
          if [ $VET_IN_DIR -eq 1 ] && [ $captured_vet_dir -eq 0 ]; then
             VET_DIR="$param"
             captured_vet_dir=1
          else
             CHECK_DIRS="$param $CHECK_DIRS"
          fi
          shift
          ;;
    esac
done

if [ $VET_IN_DIR -eq 1 ] && [ $captured_vet_dir -eq 0 ]; then
    echo "--vet-in-dir specified, but no directory provided"
    exit 1
fi

if [ "$CHECK_DIRS" == "" ]; then
    echo "No directories provided"
    exit 1
fi

if [ -f "../vendor" ]; then
    # Tell the applicable Go tools to use the vendor directory, if it exists.
    MOD_FLAGS="-mod=vendor"
fi
FMT_TMPFILE=/tmp/check_fmt
FMT_COUNT_TMPFILE=${FMT_TMPFILE}.count

fmt_count() {
    if [ ! -f $FMT_COUNT_TMPFILE ]; then
        echo "0"
    fi

    head -1 $FMT_COUNT_TMPFILE
}

fmt() {
    gofmt -d ${CHECK_DIRS//...} | tee $FMT_TMPFILE
    cat $FMT_TMPFILE | wc -l > $FMT_COUNT_TMPFILE
    if [ ! `cat $FMT_COUNT_TMPFILE` -eq "0" ]; then
        echo Found `cat $FMT_COUNT_TMPFILE` formatting issue\(s\).
        return 1
    fi
}

echo === Checking format...
fmt
FMT_RETURN_CODE=$?
echo === Finished

if [ $VET_IN_DIR -eq 1 ]; then
   cd "$VET_DIR" || exit 1
fi

echo === Vetting...
go vet ${MOD_FLAGS} ${CHECK_DIRS}
VET_RETURN_CODE=$?
echo === Finished

if [ $VET_IN_DIR -eq 1 ]; then
   cd - || exit 1
fi

echo === Linting...
(command -v golint >/dev/null 2>&1 \
    || GO111MODULE=off go get -insecure -u golang.org/x/lint/golint) \
    && golint --set_exit_status ${CHECK_DIRS}
LINT_RETURN_CODE=$?
echo === Finished

# Report output.
fail_checks=0
[ "${FMT_RETURN_CODE}" != "0" ] && echo "Formatting checks failed! => Run 'make format'." && fail_checks=1
[ "${VET_RETURN_CODE}" != "0" ] && echo "Vetting checks failed!" && fail_checks=1
[ "${LINT_RETURN_CODE}" != "0" ] && echo "Linting checks failed!" && fail_checks=1

exit ${fail_checks}
