#!/bin/bash
#
# Create a cronjob:
# @daily date '+%s' > /etc/backup/alive
#
# Now check if date is less than one week away:

t=$(date '+%s')
diff=$(( $t - $(cat /etc/backup/alive) ))

if [ $diff -gt 604800 ]; then
    logger -p syslog.err "No backup was made during the last week!"
fi
