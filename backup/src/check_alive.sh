#!/bin/bash

# Checks the age of a timestamp on file

set -euo pipefail

if [[ "${VERBOSE:-0}" == 2 ]]; then
  set -x
fi

declare -r ALIVE_FILE="${1:-/etc/backup/alive}"
declare -r ERROR_TEXT="No backup was made during the last week!"

declare -r MAX_AGE=604800
NOW=$(date '+%s')
declare -r NOW
declare -r TIME_DELTA=$(( NOW - $(cat "${ALIVE_FILE}") ))

if [[ -n ${VERBOSE+x} ]]; then
  echo "${ALIVE_FILE@A}"
  echo "${MAX_AGE@A}"
  echo "${NOW@A}"
  echo "${TIME_DELTA@A}"
fi

if [[ ${TIME_DELTA} -gt ${MAX_AGE} ]]; then
  echo "${ERROR_TEXT}" 1>&2
  logger -p syslog.err "${ERROR_TEXT}"
fi
