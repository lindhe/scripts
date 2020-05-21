#!/bin/bash

#############################################
# This is a simple battery warning script.  #
# It uses i3's nagbar to display warnings.  #
#                                           #
# @author agribu                            #
#############################################

# lock file location
export LOCK_FILE=/tmp/battery_state.lock

# check if another copy is running
if [[ -a $LOCK_FILE ]]; then

    pid=$(cat $LOCK_FILE | awk '{print $1}')
	ppid=$(cat $LOCK_FILE | awk '{print $2}')
	# validate contents of previous lock file
	vpid=${pid:-"0"}
	vppid=${ppid:-"0"}

    if (( $vpid < 2 || $vppid < 2 )); then
		# corrupt lock file $LOCK_FILE ... Exiting
		cp -f $LOCK_FILE ${LOCK_FILE}.`date +%Y%m%d%H%M%S`
		exit
	fi

    # check if ppid matches pid
	ps -f -p $pid --no-headers | grep $ppid >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
		# another copy of script running with process id $pid
		exit
	else
		# bogus lock file found, removing
		rm -f $LOCK_FILE >/dev/null
	fi

fi

pid=$$
ps -f -p $pid --no-headers | awk '{print $2,$3}' > $LOCK_FILE
# starting with process id $pid

# set Battery
BATTERY=$(ls /sys/class/power_supply/ | grep '^BAT')

# set full path
ACPI_PATH="/sys/class/power_supply/$BATTERY"

# get battery status
STAT=$(cat $ACPI_PATH/status)

# get remaining energy value
REM=`grep "POWER_SUPPLY_ENERGY_NOW" $ACPI_PATH/uevent | cut -d= -f2`

# get full energy value
FULL=`grep "POWER_SUPPLY_ENERGY_FULL_DESIGN" $ACPI_PATH/uevent | cut -d= -f2`

# get current energy value in percent
PERCENT=`echo $(( $REM * 100 / $FULL ))`

# set error message
MESSAGE="Low battery warning, find charger"

# set energy limit in percent, where warning should be displayed
LIMIT="15"

I3BAT_TMPDIR=$(mktemp --directory --tmpdir i3batwarn.XXX)
NAGBARPIDFILE="$I3BAT_TMPDIR/nagbarpid_file"

# show warning if energy limit in percent is less then user set limit and
# if battery is discharging
if [ $PERCENT -le "$(echo $LIMIT)" ] && [ "$STAT" == "Discharging" ]; then
  #chek if nagbarfile is empty: else open new - to avoid multiples
    if [ ! -s $NAGBARPIDFILE ] ; then
        /usr/bin/i3-nagbar -m "$(echo $MESSAGE)" &
        echo $! > $NAGBARPIDFILE
    elif ps -e | grep $(cat $NAGBARPIDFILE) | grep "i3-nagbar"; then
        echo "pidfile in order, nothing to do"
    else
        rm $NAGBARPIDFILE
        /usr/bin/i3-nagbar -m "$(echo $MESSAGE)" &
        echo $! > $NAGBARPIDFILE
    fi #else if, nagbarpid points to something else create new.
fi
#warning, if the nagbar is closed manually the pidfile might not be emptied properly
#for safety the charging requirement below is relaxed, if you use the nagbar for other reasons
#it might get closed accidentaly by this

if [ $PERCENT -gt "$(echo $LIMIT)" ] || [ "$STAT" == "Charging" ]
then
    if [ -s $NAGBARPIDFILE ] ; then
        if ps -e | grep $(cat $NAGBARPIDFILE) | grep "i3-nagbar"; then
            kill $(cat $NAGBARPIDFILE)
            rm $NAGBARPIDFILE
        else
            rm $NAGBARPIDFILE
        fi
    fi
fi
