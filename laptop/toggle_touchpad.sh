#!/usr/bin/env bash

set -euo pipefail

missing_dependencies=false
readonly dependencies=(
  xinput
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

ID=$(xinput --list --id-only 'SynPS/2 Synaptics TouchPad')
declare -r ID
ENABLED=$(xinput --list-props "${ID}" | grep 'Device Enabled' | awk '{print substr($0,length,1)}')
declare -r ENABLED

if [ "${ENABLED}" = "1" ]; then
    xinput --disable "${ID}"
else
    xinput --enable "${ID}"
fi
