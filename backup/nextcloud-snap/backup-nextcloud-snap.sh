#!/usr/bin/env bash
# shellcheck disable=2181

set -euo pipefail

readonly MAX_ARCHIVE_SIZE="${MAX_ARCHIVE_SIZE:-$((1024**4))}"  # Size in KiB

verbose() {
    if [[ -n ${VERBOSE+x} ]]; then
        echo "${@}"
    fi
}

debug() {
    echo "${@}" 1>&2
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

if [[ -z "${1}" ]]; then
    debug "USAGE:"
    debug "  ${0} /path/to/storage/location"
    exit
fi

readonly TARGET_BACKUP_DIR="${1/%\/}"  # Remove trailing /
verbose "${TARGET_BACKUP_DIR@A}"

verbose "Backup started …"
if [[ -n ${DEBUG+x} ]]; then
    readonly NC_EXPORT="Successfully exported /var/snap/nextcloud/common/backups/20220720-194312"
else
    if [[ -z ${VERBOSE+x} ]]; then
        MUTE="2> /dev/null"
    fi
    readonly NC_EXPORT="$(nextcloud.export "${MUTE}" | grep "Successfully exported")"
fi
verbose "${NC_EXPORT@A}"

if [[ $? -eq 0 ]]; then
    verbose "Backup finished with exit code ${?}"

    readonly NC_BACKUP_PATH="$(echo "${NC_EXPORT}" | awk '{ print $(NF) }')"
    verbose "${NC_BACKUP_PATH@A}"

    readonly NC_BACKUP_DIR="$(dirname "${NC_BACKUP_PATH}")"
    verbose "${NC_BACKUP_DIR@A}"

    readonly BACKUP_NAME="$(basename "${NC_EXPORT}")"
    verbose "${BACKUP_NAME@A}"

else
    fail "Backup finished with exit code ${?}" $?
fi

verbose "Exporting backup …"
# Using `${NC_BACKUP_DIR:1}` removes the leading slash, making the path
# relative. That, together with `-C /`, surpresses an warning print from tar
# shellcheck disable=SC2016
TAR_CMD='tar -cz -f "${TARGET_BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C / "${NC_BACKUP_PATH:1}"'
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
    if [[ $(du -k "${TARGET_BACKUP_DIR}") -ge "${MAX_ARCHIVE_SIZE}" ]]; then
        echo "WARNING: Backup archive size is greater than ${MAX_ARCHIVE_SIZE} …" 1>&2
        echo "Please check ${TARGET_BACKUP_DIR}" 1>&2
    fi
fi

