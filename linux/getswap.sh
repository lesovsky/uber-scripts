#!/bin/sh
# Get current swap usage for all running processes
for dir in $(find /proc/ -maxdepth 1 -type d |grep -E "[0-9]+"); do 
  pid=$(echo $dir |cut -d/ -f3)
  cmd=$(ps h -o comm -p $pid)
  swap=$(grep Swap $dir/smaps 2> /dev/null |awk '{sum += $2} END {print sum}')
  if [ ! -z $swap ] && [ $swap -ne 0 ]; then
	  echo "pid:$pid command:$cmd - SwapUsed: $swap KB"
  fi
done |sort -nk5 |column -t
