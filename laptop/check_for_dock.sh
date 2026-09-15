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

if [[ $# -ne 0 ]]; then
    stderr ""
    stderr "USAGE:"
    stderr "    ${0}"
    stderr ""
    exit 0
fi

missing_dependencies=false
readonly dependencies=(
  git
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

docked=false

# If the dock ethernet interface is available, we are probably docked.
if ip link show eth0 &> /dev/null; then
  docked=true
fi

# If a monitor is connected to DP-1-1 (or variants), we are probably docked.
if xrandr --query | grep -q -E 'DP-?[1-2]-[1-2] connected'; then
  docked=true
fi

if [[ "${docked}" == "true" ]]; then
  echo "Connected to dock"
  true
else
  echo "Not connected to dock"
  false
fi
