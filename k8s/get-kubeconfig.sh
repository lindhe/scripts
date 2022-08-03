#!/usr/bin/env bash

set -euo pipefail

# Get the concatenation of all files given as arugments or
# all files directly under the directories given as arguments.
CONFIG_PATHS=""
for arg in "${@}"; do
    if [[ -d ${arg} ]]; then
        if [[ "${arg}" =~ .*\. ]]; then
            # Quck fix to handle . and .. gracefully
            arg="${arg}/"
        fi
        for file in "${arg[@]}"*; do
            if [[ -f ${file} ]]; then
                CONFIG_PATHS="${CONFIG_PATHS}:$(readlink -e "${file}")"
            fi
        done
    elif [[ -f ${arg} ]]; then
        CONFIG_PATHS="${CONFIG_PATHS}:$(readlink -e ${arg})"
    else
        echo "${0} ERROR: Cannot parse ${arg}" 1>&2
    fi
done
echo "${CONFIG_PATHS#:}"
