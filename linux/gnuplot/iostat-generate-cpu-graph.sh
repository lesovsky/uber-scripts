#!/bin/bash

inputFile=$1
diskDevice=${2:-sda}
pollInterval=${3:-1}

# cpu usage (us,sy,wa)
counter=$pollInterval
grep -A1 'avg-cpu' $inputFile |grep -vE '\-\-|avg-cpu' |awk '{print $1" "$3" "$4}' | while read line; 
  do echo "$counter $line"; counter=$(($counter+$pollInterval));
  done > $inputFile-cpu.data

# graph cpu usage
datafile=$inputFile-cpu.data
outfile=$inputFile-cpu.jpg

gnuplot << EOP
set terminal jpeg font arial 8 size 640,480
set output "$outfile"
set title "CPU usage: $inputFile"
set grid x y
set xlabel "Time (sec)"
set ylabel "CPU Usage (%)"
plot "$datafile" using 1:2 title "us" with lines, \
     "$datafile" using 1:3 title "sy" with lines, \
     "$datafile" using 1:4 title "wa" with lines
EOP

rm $datafile
