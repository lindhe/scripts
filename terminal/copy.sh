#!/usr/bin/env bash
# Copy the contents of a file to the clipboard.

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

if [[ $# -ne 1 ]]; then
    stderr ""
    stderr "USAGE:"
    stderr "    ${0} <file>"
    stderr ""
    exit 0
fi

if [[ "$(uname -r)" =~ .*microsoft.* ]]; then
  declare -r IS_WSL=true
else
  declare -r IS_WSL=false
fi

if [[ "${IS_WSL}" == "true" ]]; then
  declare -r CLIPBOARD_CMD='/mnt/c/Windows/System32/clip.exe'
else
  missing_dependencies=false
  declare -r dependencies=(
    xclip
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
  declare -r CLIPBOARD_CMD='xclip -selection clipboard'
fi

${CLIPBOARD_CMD} < "${1}"
