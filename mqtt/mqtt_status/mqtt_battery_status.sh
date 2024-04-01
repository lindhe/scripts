#!/usr/bin/env bash

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
readonly dependencies=(
  dig
  mosquitto_pub
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

if [[ -z ${IAMAT+x} ]]; then
  # Catch unset IAMAT
  IAMAT="$(dig +short iamat.lindhe.io TXT)"
fi

if [[ "${IAMAT}" == '"home"' ]]; then
    mosquitto_pub \
        -t '/laptops/blaptop/battery/percentage' \
        -m "$(cat /sys/class/power_supply/BAT0/capacity)"
    mosquitto_pub \
        -t '/laptops/blaptop/battery/power/state' \
        -m "$(cat /sys/class/power_supply/AC/online)"
fi

