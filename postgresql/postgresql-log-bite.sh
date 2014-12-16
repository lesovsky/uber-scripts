#!/usr/bin/env bash
# Description:  Bite log interval from postgres log with specified interval
# Author:       Lesovsky A.V.
# Usage:        script.sh interval [input log] [output log]
# Example:      script.sh 06-11 /var/log/postgresql/postgresql.log /tmp/pglog.out
# Comment:      Log must be daily rotated.

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
interval=$1
inputLog=${2:-/var/log/postgresql/postgresql-$DATE.log}
outputLog=${3:-/tmp/pgla-$DATE.out}
date=$(head -n1 $inputLog |awk '{print $1}')

intervalStart=$(echo $interval |cut -d- -f1)
intervalEnd=$(echo $interval |cut -d- -f2)

sed -n -e "/^$date $intervalStart/,/^$date $intervalEnd/p" $inputLog > $outputLog

head -n1 $outputLog |grep -qE "^$date $intervalStart" ||echo "WARNING: first line of $outputLog does not match to start interval"
tail -n1 $outputLog |grep -qE "^$date $intervalEnd" || echo "WARNING: last line of $outputLog does not match to end interval"

echo "cut from $inputLog to $outputLog interval from $date $intervalStart to $date $intervalEnd hours"
