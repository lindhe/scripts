#!/bin/bash

if lsusb | grep "feed:1307";
then
    echo "Keyboard found";
    xset r rate 330 75;
    setxkbmap se-A5;
    exit 0;
fi
exit 1;
