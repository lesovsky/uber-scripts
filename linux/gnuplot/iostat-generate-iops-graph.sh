#!/bin/bash

inputFile=$1
diskDevice=${2:-sda}
pollInterval=${3:-1}

riopsField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -n 'r/s' |cut -d: -f1)
wiopsField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -n 'w/s' |cut -d: -f1)

counter=$pollInterval
grep $diskDevice $inputFile |awk -v r=$riopsField -v w=$wiopsField '{print $r" "$w}' | while read line;
  do echo "$counter $line"; counter=$(($counter+$pollInterval));
  done > $inputFile-iops.data

datafile=$inputFile-iops.data
outfile=$inputFile-iops.jpg

gnuplot << EOP
set terminal jpeg font arial 8 size 640,480
set output "$outfile"
set title "IOPS: $inputFile"
set grid x y
set xlabel "Time (sec)"
set ylabel "IOPS"
plot "$datafile" using 1:2 title "rIOPS" with lines, \
     "$datafile" using 1:3 title "wIOPS" with lines
EOP

rm $datafile
