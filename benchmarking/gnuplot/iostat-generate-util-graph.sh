#!/bin/bash

inputFile=$1
diskDevice=${2:-sda}
pollInterval=${3:-1}

utilField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -n '%util' |cut -d: -f1)

counter=$pollInterval
grep $diskDevice $inputFile |awk -v u=$utilField '{print $u}' | while read line;
  do echo "$counter $line"; counter=$(($counter+$pollInterval));
  done > $inputFile-util.data

datafile=$inputFile-util.data
outfile=$inputFile-util.jpg

gnuplot << EOP
set terminal jpeg font arial 8 size 640,480
set output "$outfile"
set title "CPU usage: $inputFile"
set grid x y
set xlabel "Time (sec)"
set ylabel "Utilization (%)"
plot "$datafile" using 1:2 title "utilization (%)" with lines
EOP

rm $datafile
