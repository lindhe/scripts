#!/usr/bin/env bash

set -euo pipefail

debug() {
    echo "${@}" 1>&2
}

fail() {
    debug "${1}"
    exit "${2:-1}"
}

if [[ $# -lt 2 ]]; then
    debug ""
    debug "USAGE:"
    debug "    $(basename "${0}") SSID PASSWORD [file.png]"
    debug ""
    exit 0
fi

declare -r SSID="${1}"
declare -r PASSWORD="${2//;/\\;}"  # Sanitize the password from bad characters
declare -r ENC_TYPE=WPA


if [[ $# -eq 3 ]]; then
    declare -r QR_CMD="qrencode --output=${3}"
else
    declare -r QR_CMD='qrencode -t utf8 -o -'
fi

echo -n "WIFI:S:${SSID};T:${ENC_TYPE};P:${PASSWORD};;" | ${QR_CMD}
