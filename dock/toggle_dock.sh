#!/bin/bash

RES=''

~/scripts/dock/check_for_dock.sh

if [ $? -eq 0 ]; then
    ~/scripts/dock/monman.py -a \
        && RES='Docking successful!' || RES='Docking failed!';
else
    ~/scripts/dock/monman.py -d \
        && RES='Undocking sucessful!' || RES='Undocking failed!';
fi

logger $RES;

# Resource .xprofile
~/.xprofile

