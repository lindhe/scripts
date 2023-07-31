#!/usr/bin/env bash
# shellcheck disable=2181

set -euo pipefail

if [[ -z ${VERBOSE+x} ]]; then
    VERBOSE=0
fi
declare -r VERBOSE

if [[ "${VERBOSE}" -ge 5 ]]; then
    set -x
fi

declare -r MAX_ARCHIVE_SIZE="${MAX_ARCHIVE_SIZE:-$((1024**4))}"  # Size in KiB

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

if [[ -z "${1:-}" ]]; then
    debug "USAGE:"
    debug "  ${0} /path/to/storage/location"
    exit
fi

declare -r TARGET_BACKUP_DIR="${1/%\/}"  # Remove trailing /
if [[ ${VERBOSE} -ge 1 ]]; then echo "${TARGET_BACKUP_DIR@A}"; fi

if [[ ${VERBOSE} -ge 1 ]]; then echo "Backup started …"; fi

if [[ ${VERBOSE} -eq 0 ]]; then
    NC_EXPORT_CMD='nextcloud.export 2> /dev/null'
else
    NC_EXPORT_CMD='nextcloud.export'
fi
declare -r NC_EXPORT_CMD

if [[ ${VERBOSE} -ge 1 ]]; then echo "${NC_EXPORT_CMD@A}"; fi

if [[ -n ${DEBUG+x} ]]; then
    if [[ ${VERBOSE} -ge 1 ]]; then
        # shellcheck disable=SC2005
        echo "$(eval echo "${NC_EXPORT_CMD}")"
    fi
    declare -r NC_EXPORT="Successfully exported /var/snap/nextcloud/common/backups/20220720-194312"
else
    if [[ ${VERBOSE} -ge 1 ]]; then
        # shellcheck disable=SC2005
        echo "$(eval echo "${NC_EXPORT_CMD}")" # TODO
    fi
    NC_EXPORT=$(eval "${NC_EXPORT_CMD}")
    declare -r NC_EXPORT
fi

if [[ ${VERBOSE} -ge 2 ]]; then echo "${NC_EXPORT@A}"; fi

if [[ $? -eq 0 ]]; then
    if [[ ${VERBOSE} -ge 1 ]]; then echo "Backup finished with exit code ${?}"; fi

    SUCCESS_STRING=$(echo "${NC_EXPORT}" | grep "Successfully exported") \
        || fail "Grep unexpectedly could not find substring despite successful export!"
    declare -r SUCCESS_STRING
    if [[ ${VERBOSE} -ge 2 ]]; then echo "${SUCCESS_STRING@A}"; fi

    NC_BACKUP_PATH="$(echo "${SUCCESS_STRING}" | awk '{ print $(NF) }')"
    declare -r NC_BACKUP_PATH
    if [[ ${VERBOSE} -ge 2 ]]; then echo "${NC_BACKUP_PATH@A}"; fi

    NC_BACKUP_DIR="$(dirname "${NC_BACKUP_PATH}")"
    declare -r NC_BACKUP_DIR
    if [[ ${VERBOSE} -ge 2 ]]; then echo "${NC_BACKUP_DIR@A}"; fi

    BACKUP_NAME="$(basename "${SUCCESS_STRING}")"
    declare -r BACKUP_NAME
    if [[ ${VERBOSE} -ge 2 ]]; then echo "${BACKUP_NAME@A}"; fi

else
    fail "Backup finished with exit code ${?}" $?
fi

if [[ ${VERBOSE} -ge 1 ]]; then echo "Exporting backup …"; fi
if [[ ${VERBOSE} -ge 3 ]]; then
    # shellcheck disable=SC2034
    declare -r TAR_VERBOSE="--verbose"
fi
# Using `${NC_BACKUP_DIR:1}` removes the leading slash, making the path
# relative. That, together with `-C /`, surpresses an warning print from tar
# shellcheck disable=SC2016
TAR_CMD='tar "${TAR_VERBOSE:-}" -cz -f "${TARGET_BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C / "${NC_BACKUP_PATH:1}"'
if [[ -n ${DEBUG+x} ]]; then
    # shellcheck disable=SC2005
    echo "$(eval echo "${TAR_CMD}")"
else
    eval "${TAR_CMD}"
fi

EXIT_CODE="${?}"
declare -r EXIT_CODE
if [[ ! ${EXIT_CODE} -eq 0 ]]; then
    fail "Export failed with exit code ${EXIT_CODE}" "${EXIT_CODE}"
fi
if [[ ${VERBOSE} -ge 1 ]]; then echo "Export complete!"; fi

if [[ ${VERBOSE} -ge 1 ]]; then echo "Cleaning up directory ${NC_BACKUP_PATH} …"; fi
if [[ ${VERBOSE} -ge 3 ]]; then
    # shellcheck disable=SC2034
    declare -r RM_VERBOSE="--verbose"
fi
# shellcheck disable=SC2016,2089
CLEANUP_CMD='rm "${RM_VERBOSE:-}" -rf "${NC_BACKUP_PATH}"'
if [[ -n ${DEBUG+x} ]]; then
    # shellcheck disable=SC2005
    echo "$(eval echo "${CLEANUP_CMD}")"
else
    eval "${CLEANUP_CMD}"
fi
if [[ ${VERBOSE} -ge 1 ]]; then echo "Clean-up complete!"; fi

#du -k "${TARGET_BACKUP_DIR}"
if [[ -z ${DEBUG+x} ]]; then
    if [[ "5" -ge "${MAX_ARCHIVE_SIZE}" ]]; then
        echo "WARNING: Backup archive size is greater than ${MAX_ARCHIVE_SIZE} …" 1>&2
        echo "Please check ${TARGET_BACKUP_DIR}" 1>&2
    fi
fi


if [[ ${VERBOSE} -ge 1 ]]; then
    echo "Backup complete!"
    echo "${TARGET_BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
fi
