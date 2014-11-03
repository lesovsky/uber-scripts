#!/usr/bin/env bash
# Description:    Parse pgbouncer log and print average stats.
# Version:        0.1

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
LOG=$1
DATE=${2:-$(date +%Y-%m-%d)}
TMP=$(mktemp --tmpdir=/tmp pgb.XXXX)

main() {
# parse log
for log in $LOG
do
echo "$log: $DATE"
grep "$DATE" "$log" |grep Stats > $TMP
  for i in {00..23}
    do 
      echo -n "Hour $i: "; 
      cat $TMP |grep -E " $i:" \
      |awk '{sum6+=$6; sum9+=$9; sum12+=$12; sum14+=$14} END {printf "%10.1f req/s,\t in %10.1f b/s,\t out %10.2f b/s,\t query %10.2f us\n", sum6/NR,sum9/NR,sum12/NR,sum14/NR}'
    done
rm $TMP
sleep 1
done
}

main |grep -v '\-nan'
