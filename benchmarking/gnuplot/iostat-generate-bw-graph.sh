#!/bin/bash

inputFile=$1
diskDevice=${2:-sda}
pollInterval=${3:-1}

rField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -nE 'r(sec|kB|MB)/s' |cut -d: -f1)
wField=$(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -nE 'w(sec|kB|MB)/s' |cut -d: -f1)

counter=$pollInterval
grep $diskDevice $inputFile |awk -v r=$rField -v w=$wField '{print $r" "$w}' | while read line;
  do echo "$counter $line"; counter=$(($counter+$pollInterval));
  done > $inputFile-bw.data

datafile=$inputFile-bw.data
outfile=$inputFile-bw.jpg

case $(grep -m1 '^Device:' $inputFile |xargs echo |tr ' ' '\n' |grep -E 'r(sec|kB|MB)/s') in
'rsec/s' ) unit="sectors" ;;
'rkB/s' ) unit="kB" ;;
'rMB/s' ) unit="MB" ;;
esac

gnuplot << EOP
set terminal jpeg font arial 8 size 640,480
set output "$outfile"
set title "Bandwidth: $inputFile"
set grid x y
set xlabel "Time (sec)"
set ylabel "Bandwidth ($unit)"
plot "$datafile" using 1:2 title "read ($unit)" with lines, \
     "$datafile" using 1:3 title "write ($unit)" with lines
EOP

rm $datafile
