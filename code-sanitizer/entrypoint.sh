#!/bin/bash

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DIRECTORY=$(pwd)
TOTALFOUND=0
SCRIPTNAME=$(basename "$0")

cd "${SCRIPTDIR}" || exit
for file_name in "${SCRIPTDIR}"/*.forbidden-word-list; do
  source "${file_name}"
done

function usage() {
  echo
  echo "$SCRIPTNAME"
  echo "    -d directory        - Directory to scan, default is the current working directory"
  exit 1
}

# output -
function output() {
  grep -E -iwRHI --color --line-number --exclude-dir .git --exclude-dir .github --exclude-dir .idea --exclude "*.forbidden-word-list" "${W}" .
}

# check_for_disallowed_words
# $1 = working dir
function check_for_disallowed_words() {
  cd "${DIRECTORY}" || exit
  for A in "${DISALLOWEDWORDS[@]}"; do
    IFS='|' tokens=($A)
    W="${tokens[0]}"
    T="${tokens[1]}"
    E="${tokens[2]}"

    echo

    echo "-- Checking for ${T}, with a regex of '${W}' because ${E}"

    COUNT=$(grep -E -iwRHI --color --line-number --exclude-dir .git --exclude-dir .github --exclude-dir .idea --exclude "*.forbidden-word-list" "${W}" . | wc -l)
    TOTALFOUND=$((TOTALFOUND + COUNT))

    if [ "${COUNT}" != "0" ]; then
      output
      echo
    fi
  done

}

while getopts "d:h" opt; do
  case $opt in
  d)
    DIRECTORY="${OPTARG}"
    ;;
  h)
    usage
    exit 0
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    usage
    exit 1
    ;;
  esac
done

check_for_disallowed_words "${BASEDIR}/${SOURCE_CLONE}"
echo "Total issues found: $TOTALFOUND"
exit $TOTALFOUND
