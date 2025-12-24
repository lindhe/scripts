#!/usr/bin/env bash

# {{{

set -uo pipefail

stderr() {
    echo -e "${@}" 1>&2
}

fail() {
    stderr "${1:-}"
    stderr ""
    stderr "Exiting …"
    exit "${2:-1}"
}

if [[ $# -ne 0 ]]; then
    stderr ""
    stderr "USAGE:"
    stderr "    ${0}"
    stderr ""
    exit 0
fi

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

# }}}

echo -e "Subject: Virus found by ClamAV\!\n\nClamAV scanned ${CLAM_VIRUSEVENT_FILENAME} and found virus ${CLAM_VIRUSEVENT_VIRUS}\!" \
  | sendmail root
