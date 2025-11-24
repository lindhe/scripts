#!/usr/bin/env bash
# Paste to stdout from the clipboard.

set -uo pipefail

stderr() {
    echo "${@}" 1>&2
}

fail() {
    stderr "${1}"
    stderr ""
    stderr "Exiting …"
    exit "${2:-1}"
}

wsl_paste() {
  powershell.exe -c 'Get-Clipboard'
}

if [[ "$(uname -r)" =~ .*microsoft.* ]]; then
  declare -r IS_WSL=true
else
  declare -r IS_WSL=false
fi

if [[ "${IS_WSL}" == "true" ]]; then
  wsl_paste
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
  xclip -o -selection clipboard
fi
