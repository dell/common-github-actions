#!/bin/bash

GOSEC_ARGS=("$@")

echo === Running gosec...
gosec ${GOSEC_ARGS[*]}
GOSEC_RETURN_CODE=$?
echo === Finished

fail_checks=0
[ "${GOSEC_RETURN_CODE}" != "0" ] && echo "Security checks failed!" && fail_checks=1

exit ${fail_checks}
