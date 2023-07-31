#!/bin/bash

RES=''
SCRIPTS_LOCATION="${HOME}/git/lindhe/scripts"

if "${SCRIPTS_LOCATION}"/dock/check_for_dock.sh; then
    "${SCRIPTS_LOCATION}"/dock/monman.py -a ${IAMAT:+~/.config/monitors/${IAMAT}.json} \
        && RES='Docking successful!' || RES='Docking failed!';
else
    "${SCRIPTS_LOCATION}"/dock/monman.py -d \
        && RES='Undocking sucessful!' || RES='Undocking failed!';
fi

logger "${RES}";

~/.xprofile
