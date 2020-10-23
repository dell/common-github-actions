#!/bin/bash

CHECK_DIRS="$*"

if [ -f "../vendor" ]; then
    # Tell the applicable Go tools to use the vendor directory, if it exists.
    MOD_FLAGS="-mod=vendor"
fi

echo === Running gosec...
gosec -quiet ${MOD_FLAGS} ${CHECK_DIRS}
SEC_RETURN_CODE=$?
echo === Finished

fail_checks=0
[ "${SEC_RETURN_CODE}" != "0" ] && echo "Security checks failed!" && fail_checks=1
exit ${fail_checks}