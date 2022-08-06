#!/usr/bin/env bash
# vim: set ts=4 sw=4:

# Checks for authorized Wi-Fi SSID or connected Ethernet before performing
# backup.

set -euo pipefail

if [[ "${VERBOSE:-0}" == 2 ]]; then
  set -x
fi


# The first argument given, $1, will be treated as the --max-size
# If $1 is empty, --max-size is not used.
readonly MAX_SIZE="${1:+ --max-size ${1}}"

readonly BACKUP_SCRIPT_DIR='/etc/backup'

# Update alive file
set +e
(umask 033; date '+%s' > ${BACKUP_SCRIPT_DIR}/alive)
set -e

readonly HOST=$(hostname)
readonly CHARGING=$(acpi --ac-adapter | grep "on-line")
readonly WLAN_SSID=$(iwgetid --raw);
readonly LIST_OF_ETH_IF=(
    eth0
    eth1
)
readonly BACKUP_SOURCE_DIR='/'

if [[ -n ${LOCAL_BACKUP+x} ]]; then
    BACKUP_TARGET_DIR='/storage/backups/server/bserver/'
    RUN=true
else
    BACKUP_TARGET_DIR='backup:/'
    RUN=false
fi
readonly BACKUP_TARGET_DIR

readonly WLAN_IS_METERED="$(nmcli -g connection.metered connection show "${WLAN_SSID}")"

readonly LOG_PREFIX='Backup:'

# print to both stdout and log
logprint () {
    if [[ -n ${VERBOSE+x} ]]; then
        echo "${LOG_PREFIX} ${1}"
    fi
    logger "${LOG_PREFIX} ${1}"
    if (command -v notify-send &> /dev/null); then
      notify-send --urgency=low "${LOG_PREFIX} ${1}\n\nPlease check journalctl for more info."
    fi
}

# print to both stderr and log
logprint_err () {
    echo "${LOG_PREFIX} ${1}" 1>&2
    logger -p syslog.err "${LOG_PREFIX} ${1}"
    if (command -v notify-send &> /dev/null); then
      notify-send --urgency=critical "${LOG_PREFIX} ${1}\n\nPlease check journalctl for more info."
    fi
}

if [[ -n ${DEBUG+x} ]]; then
  RSYNC_CMD="echo rsync"
else
  RSYNC_CMD="rsync"
fi
readonly RSYNC_CMD

readonly RSYNC_FLAGS="-azAX --partial --delete --delete-excluded --exclude-from=${BACKUP_SCRIPT_DIR}/exclude.txt"

if [[ -z ${LOCAL_BACKUP+x} ]]; then  # Check conditions for remote backup
    # Check which device is used for default route
    DEFAULT_ROUTE_DEV=$(ip route show default | cut -d ' ' -f 5)

    # Determine network connection type
    CONNECTED_VIA_ETHERNET=false
    # Note that this check if an ethernet dev is a default route, but WLAN devices
    # might also be default routes (since there might be many). Not sure how to work
    # around this.
    for DEV in "${LIST_OF_ETH_IF[@]}"; do
        for ROUTE_DEV in "${DEFAULT_ROUTE_DEV[@]}"; do
            if [[ "${DEV}" = "${ROUTE_DEV}" ]]; then
                CONNECTED_VIA_ETHERNET=true
            fi
        done
    done

    # We'll always backup if charging or just making a small backup
    if [ -n "$CHARGING" ] || [ -n "${MAX_SIZE}" ]; then
        # Ethernet connection is always OK for backup
        if [[ "${CONNECTED_VIA_ETHERNET}" = "true" ]]; then
            logprint "Performing backup over Ethernet (${DEFAULT_ROUTE_DEV})";
            RUN=true;
        # WLAN is OK if it's not metered
        elif [[ "${WLAN_IS_METERED}" == "no" ]]; then
            logprint "Performing backup over Wi-fi: $WLAN_SSID";
            RUN=true;
        else
            logprint_err "Prohibited backup since ${WLAN_SSID} is metered.";
        fi
    else
        logprint_err "Not charging. Prohibiting backup."
    fi
fi

if $RUN; then
    logprint "Backup of $HOST started at $(date +'%F_%T')";
    if [ -n "${MAX_SIZE}" ]; then
        logprint "Only backing up files smaller than ${1}"
    fi

    if ${RSYNC_CMD} "${RSYNC_FLAGS}${MAX_SIZE}" "${BACKUP_SOURCE_DIR}" "${BACKUP_TARGET_DIR}"; then
        logprint "Backup of $HOST finished $(date +'%F_%T')" \
    else
        logprint_err "Backup of $HOST failed $(date +'%F_%T')"
    fi

else
    logprint_err "Backup of $HOST failed $(date +'%F_%T')";
    exit 1;
fi
