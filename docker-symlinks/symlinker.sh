#!/usr/bin/env bash

set -euo pipefail

debug() {
    echo "${@}" 1>&2
}

fail() {
    stderr "${1}"
    exit "${2:-1}"
}

declare -r DEFAULT_SUFFIX='-json.log'
declare -r DEFAULT_SRC_DIR='/var/lib/docker/containers'

if [[ $# -lt 1 ]]; then
    stderr ""
    stderr "Symlinks Docker logs to DST_DIR and prints each container's SHA"
    stderr ""
    stderr "USAGE:"
    stderr "    ${0} DST_DIR [SUFFIX] [SRC_DIR]"
    stderr ""
    stderr "DEFAULTS:"
    stderr "    SUFFIX='${DEFAULT_SUFFIX}'"
    stderr "    SRC_DIR='${DEFAULT_SRC_DIR}'"
    stderr ""
    exit 0
fi

declare -r DST_DIR="${1}"
declare -r SUFFIX="${2:-"${DEFAULT_SUFFIX}"}"
declare -r SRC_DIR="${3:-"${DEFAULT_SRC_DIR}"}"

if [ ! -r "${SRC_DIR}" ]; then
  fail "ERROR: User do not have read access to ${SRC_DIR}"
fi

for dir in "${SRC_DIR}"/*; do
  container="$(basename "${dir}")"
  echo "${container}"
  logfile="${dir}/${container}${SUFFIX}"
  ln -sf "${logfile}" -t "${DST_DIR}"
done

find "${DST_DIR}" -xtype l -exec rm {} \;
