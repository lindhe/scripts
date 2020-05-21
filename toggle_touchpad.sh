#!/bin/bash
ID=$(xinput --list --id-only 'SynPS/2 Synaptics TouchPad')
ENABLED=$(xinput --list-props $ID | grep 'Device Enabled' | awk '{print substr($0,length,1)}')

if [ "$ENABLED" = "1" ]; then
    xinput --disable $ID
else
    xinput --enable $ID
fi;
