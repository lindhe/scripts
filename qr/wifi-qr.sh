#!/usr/bin/env bash

set -euo pipefail

debug() {
    echo "${@}" 1>&2
}

fail() {
    debug "${1}"
    exit "${2:-1}"
}

if [[ $# -ne 2 ]]; then
    debug ""
    debug "USAGE:"
    debug "    ${0} SSID PASSWORD"
    debug ""
    exit 0
fi

readonly SSID="${1}"
readonly PASSWORD="${2//;/\\;}"  # Sanitize the password from bad characters
readonly ENC_TYPE=WPA

echo -n "WIFI:S:${SSID};T:${ENC_TYPE};P:${PASSWORD};;" | qrencode -t utf8 -o -
