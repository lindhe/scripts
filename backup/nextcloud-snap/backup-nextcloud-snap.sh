#!/usr/bin/env bash
# shellcheck disable=SC2034,2181

set -euo pipefail

MAX_ARCHIVE_SIZE="${MAX_ARCHIVE_SIZE:-$((1024**4))}"  # Size in KiB

verbose() {
    if [[ -n ${VERBOSE+x} ]]; then
        echo "${@}"
    fi
}

fail() {
    echo "FAILURE: ${1:-exiting}" 1>&2
    exit "${2:-1}"
}

if [[ -z ${DEBUG+x} ]]; then
    if [ "$EUID" -ne 0 ]; then
        fail "Please run as root"
    fi
fi

readonly TARGET_BACKUP_DIR=${1}
verbose "TARGET_BACKUP_DIR=${TARGET_BACKUP_DIR}"

verbose "Starting backup …"
if [[ -n ${DEBUG+x} ]]; then
    readonly NC_EXPORT="Successfully exported /var/snap/nextcloud/common/backups/20220720-194312"
else
    readonly NC_EXPORT=$(nextcloud.export 2> /dev/null | grep "Successfully exported")
fi

if [[ $? -eq 0 ]]; then
    verbose "Backup finished with exit code ${?}"
    verbose "NC_EXPORT=${NC_EXPORT}"
    readonly NC_BACKUP_PATH=$(echo "${NC_EXPORT}" | awk '{ print $(NF) }')
    readonly NC_BACKUP_DIR="$(dirname "${NC_BACKUP_PATH}")"
    readonly BACKUP_NAME="$(basename "${NC_EXPORT}")"
else
    fail "Backup finished with exit code ${?}" $?
fi

verbose "Exporting backup …"
# shellcheck disable=SC2016
TAR_CMD='tar -cz -C / -f "${NC_BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "${NC_BACKUP_PATH}"'
if [[ -n ${DEBUG+x} ]]; then
    echo "${TAR_CMD}"
else
    eval "${TAR_CMD}"
fi

if [[ ! $? -eq 0 ]]; then
    fail "Export failed with exit code ${?}" $?
fi
verbose "Export complete!"

verbose "Cleaning up directory …"
# shellcheck disable=SC2016
CLEANUP_CMD='rm -rf "${NC_BACKUP_PATH}"'
if [[ -n ${DEBUG+x} ]]; then
    echo "${CLEANUP_CMD}"
else
    eval "${CLEANUP_CMD}"
fi
verbose "Clean-up complete!"

if [[ -z ${DEBUG+x} ]]; then
    if [[ $(du -k "${TARGET_BACKUP_DIR}") -ge ${MAX_ARCHIVE_SIZE} ]]; then
        echo "WARNING: Backup archive size is greater than ${MAX_ARCHIVE_SIZE} …" 1>&2
        echo "Please check ${TARGET_BACKUP_DIR}" 1>&2
    fi
fi

