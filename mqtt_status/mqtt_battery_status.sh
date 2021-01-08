#!/usr/bin/env bash

# Put this in a cronjob

if [[ "${IAMAT}" == "home" ]]; then
    mosquitto_pub \
        -t '/laptop/battery/capacity' \
        -m "$(cat /sys/class/power_supply/BAT0/capacity)"
    mosquitto_pub \
        -t '/laptop/battery/charging' \
        -m "$(cat /sys/class/power_supply/AC/online)"
fi

