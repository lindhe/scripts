#!/usr/bin/env bash
# Copy stdin or file contents into the clipboard.

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

if [[ $# -eq 0 ]]; then
  # no args => stdin
  ${CLIPBOARD_CMD}
else
  ${CLIPBOARD_CMD} < "${1}"
fi
