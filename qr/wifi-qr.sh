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
    debug "    ${0} SSID PASSWORD [file.png]"
    debug ""
    exit 0
fi

readonly SSID="${1}"
readonly PASSWORD="${2//;/\\;}"  # Sanitize the password from bad characters
readonly ENC_TYPE=WPA


if [[ $# -eq 3 ]]; then
    readonly QR_CMD="qrencode --output=${3}"
else
    readonly QR_CMD='qrencode -t utf8 -o -'
fi

echo -n "WIFI:S:${SSID};T:${ENC_TYPE};P:${PASSWORD};;" | ${QR_CMD}
