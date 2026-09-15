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

wsl_copy() {
  # This function is superior to Windows' copy.exe, since it does not mess up
  # text encoding by asssuming BOM.
  # https://github.com/microsoft/WSL/issues/10095#issuecomment-1602833117
  INPUT="$(cat; echo x)"
  declare -r INPUT="${INPUT%x}" # https://stackoverflow.com/a/32365596/893211
# Note that the string terminator '@ must be on a separate line and must not
# have leading whitespace:
# https://devblogs.microsoft.com/scripting/powershell-for-programmers-here-strings-there-strings-everywhere-some-string-strings/
powershell.exe -c "Set-Clipboard @'
${INPUT}
'@
"
}

if [[ "$(uname -r)" =~ .*microsoft.* ]]; then
  declare -r IS_WSL=true
else
  declare -r IS_WSL=false
fi

if [[ "${IS_WSL}" == "true" ]]; then
  declare -r CLIPBOARD_CMD=wsl_copy
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
