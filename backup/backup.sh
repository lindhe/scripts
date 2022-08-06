#!/usr/bin/env bash
# shellcheck disable=SC2015

# Checks for authorized Wi-Fi SSID or connected Ethernet before performing
# backup.

# Copyright 2022 Andreas Lindhé
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

# The first argument given, $1, will be treated as the --max-size
# If $1 is empty, --max-size is not used.
MAX_SIZE="${1:+--max-size ${1}}"

BACKUP_SCRIPT_DIR='/etc/backup'

# Update alive file
(umask 033; date '+%s' > ${BACKUP_SCRIPT_DIR}/alive)

HOST=$(hostname)
RUN=false;
CHARGING=$(acpi --ac-adapter | grep "on-line")
WLAN_SSID=$(iwgetid --raw);
LIST_OF_ETH_IF=(
    eth0
    eth1
)

WLAN_IS_METERED="$(nmcli -g connection.metered connection show "${WLAN_SSID}")"

# print to both stdout and log
logprint () {
    echo "${1}"
    logger "${1}"
}

# print to both stderr and log
logprint_err () {
    echo "${1}" 1>&2
    logger -p syslog.err "${1}"
    notify-send --urgency=critical 'Backup error' \
        "${1}\n\nPlease check journalctl for more info."
}

if [[ -n ${RUN_LOCALLY+x} ]]; then

  rsync -azAX --partial --delete --exclude-from=/etc/backup/exclude.txt \
      --delete-excluded / \
      /storage/backups/server/bserver/ \
      && (echo "Backup finished $(date +'%F_%T')"; \
          logger "Backup finished $(date +'%F_%T')") \
      || (echo "Backup failed $(date +'%F_%T')"; \
          logger -p syslog.err "Backup failed $(date +'%F_%T')")

else
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

  if $RUN; then
      logprint "Backup of $HOST started at $(date +'%F_%T')";
      if [ -n "${MAX_SIZE}" ]; then
          logprint "Only backing up files smaller than ${1}"
      fi
      rsync -aAX --partial --delete --delete-excluded / \
          --exclude-from=${BACKUP_SCRIPT_DIR}/exclude.txt \
          "${MAX_SIZE}" \
          backup:/ \
          && logprint "Backup of $HOST finished $(date +'%F_%T')" \
          || logprint_err "Backup of $HOST failed $(date +'%F_%T')"
  else
      logprint_err "Backup of $HOST failed $(date +'%F_%T')";
      exit 1;
  fi

fi
