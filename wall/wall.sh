#!/usr/bin/env bash
#
# License: MIT
# Author: Andreas Lindhé

set -euo pipefail

stderr() {
    echo "${@}" 1>&2
}

fail() {
    stderr "${1}"
    stderr ""
    stderr "Exiting …"
    exit "${2:-1}"
}

missing_dependencies=false
declare -r dependencies=(
  sendmail
)
for dep in "${dependencies[@]}"; do
  if ! command -v "${dep}" &> /dev/null; then
    stderr "❌ ERROR: Missing dependency ${dep}"
    missing_dependencies=true
  fi
done
if ${missing_dependencies}; then
  fail 'Please install the missing dependencies!'
fi

if [[ $# -eq 0 ]]; then
    # no args => stdin
    readarray inputarray
else
    inputarray=("${@}")
fi
declare -r inputarray

logger "Message from wall:
${inputarray[*]}
"

echo -e "Subject: Message from wall\n\nThis was captured by wall:\n${inputarray[*]}" \
    | sendmail root

/usr/bin/wall "${inputarray[*]}"
