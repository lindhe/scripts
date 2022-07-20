#!/usr/bin/env bash
# shellcheck disable=2181

if [[ "${VERBOSE:-0}" == "4" ]]; then
    set -x
fi

set -euo pipefail

readonly MAX_ARCHIVE_SIZE="${MAX_ARCHIVE_SIZE:-$((1024**4))}"  # Size in KiB

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
if [[ "${VERBOSE}" == "2" ]]; then echo "${TARGET_BACKUP_DIR@A}"; fi

if [[ -n ${VERBOSE+x} ]]; then echo "Backup started …"; fi
if [[ -n ${DEBUG+x} ]]; then
    readonly NC_EXPORT="Successfully exported /var/snap/nextcloud/common/backups/20220720-194312"
else
    if [[ -z ${VERBOSE+x} ]]; then
        MUTE="2> /dev/null"
    fi
    readonly NC_EXPORT="$(nextcloud.export "${MUTE}" | grep "Successfully exported")"
fi
if [[ "${VERBOSE}" == "2" ]]; then echo "${NC_EXPORT@A}"; fi

if [[ $? -eq 0 ]]; then
    if [[ -n ${VERBOSE+x} ]]; then echo "Backup finished with exit code ${?}"; fi

    readonly NC_BACKUP_PATH="$(echo "${NC_EXPORT}" | awk '{ print $(NF) }')"
    if [[ "${VERBOSE}" == "2" ]]; then echo "${NC_BACKUP_PATH@A}"; fi

    readonly NC_BACKUP_DIR="$(dirname "${NC_BACKUP_PATH}")"
    if [[ "${VERBOSE}" == "2" ]]; then echo "${NC_BACKUP_DIR@A}"; fi

    readonly BACKUP_NAME="$(basename "${NC_EXPORT}")"
    if [[ "${VERBOSE}" == "2" ]]; then echo "${BACKUP_NAME@A}"; fi

else
    fail "Backup finished with exit code ${?}" $?
fi

if [[ -n ${VERBOSE+x} ]]; then echo "Exporting backup …"; fi
# Using `${NC_BACKUP_DIR:1}` removes the leading slash, making the path
# relative. That, together with `-C /`, surpresses an warning print from tar
# shellcheck disable=SC2016
TAR_CMD='tar "${VERBOSE+-v}" -cz -f "${TARGET_BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C / "${NC_BACKUP_PATH:1}"'
if [[ -n ${DEBUG+x} ]]; then
    echo "${TAR_CMD}"
else
    eval "${TAR_CMD}"
fi

if [[ ! $? -eq 0 ]]; then
    fail "Export failed with exit code ${?}" $?
fi
if [[ -n ${VERBOSE+x} ]]; then echo "Export complete!"; fi

if [[ -n ${VERBOSE+x} ]]; then echo "Cleaning up directory …"; fi
# shellcheck disable=SC2016
CLEANUP_CMD='rm ${VERBOSE+-v} -rf "${NC_BACKUP_PATH}"'
if [[ -n ${DEBUG+x} ]]; then
    echo "${CLEANUP_CMD}"
else
    eval "${CLEANUP_CMD}"
fi
if [[ -n ${VERBOSE+x} ]]; then echo "Clean-up complete!"; fi

if [[ -z ${DEBUG+x} ]]; then
    if [[ $(du -k "${TARGET_BACKUP_DIR}") -ge "${MAX_ARCHIVE_SIZE}" ]]; then
        echo "WARNING: Backup archive size is greater than ${MAX_ARCHIVE_SIZE} …" 1>&2
        echo "Please check ${TARGET_BACKUP_DIR}" 1>&2
    fi
fi

