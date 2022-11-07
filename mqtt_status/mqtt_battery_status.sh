#!/usr/bin/env bash

# Put this in a cronjob

if [[ "${IAMAT}" == "home" ]]; then
    mosquitto_pub \
        -t '/laptops/blaptop/battery/percentage' \
        -m "$(cat /sys/class/power_supply/BAT0/capacity)"
    mosquitto_pub \
        -t '/laptops/blaptop/battery/power/state' \
        -m "$(cat /sys/class/power_supply/AC/online)"
fi

