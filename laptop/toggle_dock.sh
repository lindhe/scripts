#!/usr/bin/env bash

set -euo pipefail

LOG_LINE=''
declare -r SCRIPTS_LOCATION="${HOME}/git/lindhe/scripts"

if "${SCRIPTS_LOCATION}"/laptop/check_for_dock.sh; then
    "${SCRIPTS_LOCATION}"/laptop/monman.py -a ${IAMAT:+~/.config/monitors/${IAMAT}.json} \
        && LOG_LINE='Docking successful!' || LOG_LINE='Docking failed!';
else
    "${SCRIPTS_LOCATION}"/dock/monman.py -d \
        && LOG_LINE='Undocking sucessful!' || LOG_LINE='Undocking failed!';
fi

logger "${LOG_LINE}";

# Run .xprofile to set Keyboard etc.
~/.xprofile
