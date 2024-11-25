#!/usr/bin/env bash
# A smart wrapper for base64 decoding.

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
  base64
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

if [[ -p /dev/stdin ]]; then
  INPUT="$(cat -)"
else
  INPUT="${*}"
fi

echo -n "${INPUT}" | base64 -d ; echo
