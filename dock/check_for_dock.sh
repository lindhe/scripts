#!/bin/bash
#
# Returns True if docked

# If the dock ethernet interface is available, we are probably docked.
ip link show eth0 2> /dev/null > /dev/null;
eth_if=$?

# If a monitor is connected to DP-1-1 (or variants), we are probably docked.
monitors=$(xrandr --query | grep -E 'DP-[1-2]-[1-2] connected')

if [ "$eth_if" == 0 ] || [ -n "$monitors" ]; then
  echo "Connected to dock"
  true
else
  echo "Not connected to dock"
  false
fi
