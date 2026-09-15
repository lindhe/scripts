#!/usr/bin/env bash

# {{{

set -euo pipefail

stderr() {
    echo -e "${@}" 1>&2
}

fail() {
    stderr "${1:-}"
    stderr ""
    stderr "Exiting …"
    exit "${2:-1}"
}

if [[ $# -eq 1 ]]; then
  if [[ "${1}" == "-h" ]]; then
      stderr ""
      stderr "USAGE:"
      stderr "    echo 'foo.bar.boo.far' | ${0}"
      stderr "    ${0} 'foo.bar.boo.far'"
      stderr ""
      exit 0
  fi
fi

if [[ $# -eq 0 ]]; then
    # no args => stdin
    readarray inputarray
else
    inputarray=("${@}")
fi
declare -r inputarray

# }}}

if [[ ${inputarray[0]} =~ "=" ]]; then
  # If a.b.c=foo, split it:
  path_string="$( echo "${inputarray[0]}" | cut -d '=' -f 1)"
  value_string="$( echo "${inputarray[0]}" | cut -d '=' -f 2)"
else
  path_string="${inputarray[0]}"
  value_string=""
fi
declare -r path_string value_string

SPACES_PER_INDENTATION=2

indentations=0
for part in ${path_string//./ }; do
  spaces=$((indentations*SPACES_PER_INDENTATION))
  if [[ ${spaces} -eq 0 ]]; then
    echo -en "${part}:"
  else
    echo -en "\n$(printf ' %.0s' $(seq ${spaces}))${part}:"
  fi
  indentations=$((indentations+1))
done
echo -en " ${value_string}\n"
