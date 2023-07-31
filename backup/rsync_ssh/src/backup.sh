#!/usr/bin/env bash
# vim: set ts=4 sw=4 fdm=marker:

# Checks for authorized Wi-Fi SSID or connected Ethernet before performing
# backup.

###############################     preamble     ###############################{{{
set -euo pipefail

if [[ "${#}" -lt 2 ]]; then
    echo "USAGE:"
    echo "  ${0} SOURCE DESTINATION [MAX_SIZE]"
    echo ""
    echo "EXAMPLES:"
    echo "  ${0} / foo@server:/ 1M"
    echo "  ${0} /home/foo /backups/users/foo"
    echo ""
    exit
fi

stderr() {
    echo "${@}" 1>&2
}

fail() {
    stderr "${1}"
    stderr ""
    stderr "Exiting …"
    exit "${2:-1}"
}

missing_dependencies=false
declare -r dependencies=(
    logger
    nmcli
    notify-send
    rsync
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
if [[ "${VERBOSE:-0}" == 2 ]]; then
  set -x
fi

#}}}

##############################     constants     ##############################{{{

# Args
declare -r BACKUP_SOURCE="${1}"
declare -r BACKUP_DESTINATION="${2}"
declare -r MAX_SIZE="${3:+ --max-size ${3}}"

declare -r BACKUP_SCRIPT_DIR='/etc/backup'
CHARGING=$(acpi --ac-adapter | grep "on-line")
declare -r CHARGING
WLAN_SSID=$(iwgetid --raw);
declare -r WLAN_SSID
declare -r LIST_OF_ETH_IF=(
    eth0
    eth1
)

if [[ -n ${LOCAL_BACKUP+x} ]]; then
    RUN=true
else
    RUN=false
fi

WLAN_IS_METERED="$(nmcli -g connection.metered connection show "${WLAN_SSID}")"
declare -r WLAN_IS_METERED
declare -r LOG_PREFIX='Backup:'

declare -r RSYNC_FLAGS="-azAX --partial --delete --delete-excluded --exclude-from=${BACKUP_SCRIPT_DIR}/exclude.txt"
declare -r RSYNC_ARGS=(
    "${MAX_SIZE}"
    "${BACKUP_SOURCE}"
    "${BACKUP_DESTINATION}"
)

if [[ -n ${DEBUG_FAIL+x} ]]; then
  RSYNC_CMD="false"
  HOST="DEBUG $(hostname)"
elif [[ -n ${DEBUG+x} ]]; then
  RSYNC_CMD="echo rsync ${RSYNC_FLAGS} ${RSYNC_ARGS[*]}"
  HOST="DEBUG $(hostname)"
else
  RSYNC_CMD="rsync ${RSYNC_FLAGS} ${RSYNC_ARGS[*]}"
  HOST="$(hostname)"
fi
declare -r HOST
declare -r RSYNC_CMD

#}}}

##############################     functions     ##############################{{{

# print to both stdout and log
logprint() {
    if [[ -n ${VERBOSE+x} ]]; then
        echo "${LOG_PREFIX} ${1}"
    fi
    logger "${LOG_PREFIX} ${1}"
    if (command -v notify-send &> /dev/null); then
        notify-send --urgency=low "${LOG_PREFIX} ${1}\n\nPlease check journalctl for more info."
    fi
}

# print to both stderr and log
logprint_err() {
    stderr "${LOG_PREFIX} ${1}"
    logger -p syslog.err "${LOG_PREFIX} ${1}"
    if (command -v notify-send &> /dev/null); then
        notify-send --urgency=critical "${LOG_PREFIX} ${1}\n\nPlease check journalctl for more info."
    fi
}
#}}}

##########################     Update alive file     ##########################{{{
set +e
(umask 033; date '+%s' > ${BACKUP_SCRIPT_DIR}/alive)
set -e
#}}}

#########################     Check preconditions     #########################{{{
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
        if [[ "${CONNECTED_VIA_ETHERNET}" = "true" ]]; then
            # Ethernet connection is always OK for backup
            logprint "Performing backup over Ethernet (${DEFAULT_ROUTE_DEV})";
            RUN=true;
        elif [[ "${WLAN_IS_METERED}" == "no" ]]; then
            # WLAN is OK if it's not metered
            logprint "Performing backup over Wi-fi: $WLAN_SSID";
            RUN=true;
        else
            logprint_err "Prohibited backup since ${WLAN_SSID} is metered.";
        fi
    else
        logprint_err "Not charging. Prohibiting backup."
    fi

fi
#}}}

##############################     Run backup     ##############################{{{
if ${RUN}; then
    logprint "Backup of ${HOST} started at $(date +'%F_%T')";
    if [ -n "${MAX_SIZE}" ]; then
        logprint "Only backing up files no larger than ${MAX_SIZE}"
    fi
    if ${RSYNC_CMD}; then
        logprint "Backup of ${HOST} finished $(date +'%F_%T')"
    else
        logprint_err "Backup of ${HOST} failed $(date +'%F_%T'). Unable to run command."
        exit 1
    fi
else
    logprint_err "Backup of ${HOST} failed $(date +'%F_%T'). RUN condition not met."
    exit 1
fi
#}}}
