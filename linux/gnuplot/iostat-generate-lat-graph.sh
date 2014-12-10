#!/bin/bash

inputFile=$1
diskDevice=${2:-sda}
pollInterval=${3:-1}

awaitField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -w -n 'await' |cut -d: -f1)
rawaitField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -n 'r_await' |cut -d: -f1)
wawaitField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -n 'w_await' |cut -d: -f1)

counter=$pollInterval
if [ -z $rawaitField -a -z $wawaitField ]
  then grep $diskDevice $inputFile |awk -v a=$awaitField '{print $a}' | while read line;
         do echo "$counter $line"; counter=$(($counter+$pollInterval));
         done > $inputFile-lat.data
  else grep $diskDevice $inputFile |awk -v a=$awaitField -v r=$rawaitField -v w=$wawaitField '{print $a" "$r" "$w}' | while read line;
         do echo "$counter $line"; counter=$(($counter+$pollInterval));
         done > $inputFile-lat.data
fi

datafile=$inputFile-lat.data
outfile=$inputFile-lat.jpg

if [ -z $rawaitField -a -z $wawaitField ]
  then plotCmd="plot \"$datafile\" using 1:2 title \"await (msec)\" with lines"
  else plotCmd="plot \"$datafile\" using 1:2 title \"await (msec)\" with lines, \"$datafile\" using 1:3 title \"r_await (msec)\" with lines, \"$datafile\" using 1:4 title \"w_await (msec)\" with lines"
fi

gnuplot << EOP
set terminal jpeg font arial 8 size 640,480
set output "$outfile"
set title "Latency: $inputFile"
set grid x y
set xlabel "Time (sec)"
set ylabel "Latency (msec)"
$plotCmd
EOP

rm $datafile
