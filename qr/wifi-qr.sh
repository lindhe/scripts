#!/usr/bin/env bash

# {{{

set -uo pipefail

stderr() {
    echo "${@}" 1>&2
}

fail() {
    stderr "${1}"
    exit "${2:-1}"
}

if [[ $# -lt 2 ]]; then
    stderr ""
    stderr "USAGE:"
    stderr "    $(basename "${0}") SSID PASSWORD [file.png]"
    stderr ""
    exit 0
fi

missing_dependencies=false
declare -r dependencies=(
  qrencode
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

declare -r SSID="${1}"
declare -r PASSWORD="${2//;/\\;}"  # Sanitize the password from bad characters
declare -r ENC_TYPE=WPA


if [[ $# -eq 3 ]]; then
  declare -ar FLAGS=("--output=${3}")
else
  declare -ar FLAGS=('-t' 'utf8' '-o' '-')
fi

echo -n "WIFI:S:${SSID};T:${ENC_TYPE};P:${PASSWORD};;" | qrencode "${FLAGS[@]}"
