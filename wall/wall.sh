#!/usr/bin/env bash

# Wrapper for the wall command.
#
# My intention with this scirpt is to intercept anything written to wall and
# broadcast it to a more accessable place like syslog and/or mail.
#
# Inspired by https://unix.stackexchange.com/a/541763/33928
#
# License: MIT
# Author: Andreas Lindhé

set -euo pipefail

if [[ $# -eq 0 ]]; then
    # no args => stdin
    readarray inputarray
else
    inputarray=("${@}")
fi
readonly inputarray


logger "Message from wall:
${inputarray[*]}
"

echo -e "Subject: Message from wall\n\nThis was captured by wall:\n${inputarray[*]}" \
    | sendmail root

wall.orig "${inputarray[*]}"
