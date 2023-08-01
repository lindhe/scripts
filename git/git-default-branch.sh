#!/usr/bin/env bash

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

if [[ $# -ne 0 ]]; then
    stderr ""
    stderr "USAGE:"
    stderr "    ${0}"
    stderr ""
    exit 0
fi

missing_dependencies=false
declare -r dependencies=(
  git
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

declare -r common_default_branches=(
  main
  master
  dev
  development
)

if git symbolic-ref -q refs/remotes/origin/HEAD > /dev/null; then
  basename "$(git symbolic-ref refs/remotes/origin/HEAD)"
  exit 0
else
  for branch in "${common_default_branches[@]}"; do
    if git branch -l "${branch}"; then
      echo "${branch}"
      exit 0
    fi
  done
fi

git config init.defaultbranch || echo "${common_default_branches[0]}"
