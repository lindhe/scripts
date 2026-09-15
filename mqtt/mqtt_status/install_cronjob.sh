#!/usr/bin/env bash

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

if [[ $# -ne 1 ]]; then
    stderr ""
    stderr "USAGE:"
    stderr "    ${0} FOO"
    stderr ""
    exit 0
fi

missing_dependencies=false
readonly dependencies=(
  crontab
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

declare -r SCRIPT_FILE="${HOME}/git/lindhe/scripts/mqtt_status/mqtt_battery_status.sh"
declare -r MQTT_HOST="mqtt.lindhe.io"

{ crontab -l; echo "* * * * * ${SCRIPT_FILE} ${MQTT_HOST}"; } \
  | sed -e 's/^#.*//' -e '/^[[:space:]]*$/d' \
  | sort -u \
  | crontab - 
