#!/usr/local/bin/bash
# Description:  Get various data an print it to stdout.
# Author:       Lesovsky A.V.           Revision:       0.1

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
pgGucs="fsync synchronous_commit full_page_writes max_connections"
PARAM=$1

function fsDiscovery {
  echo -n '{"data":['
  mount |grep -w -E 'ufs' |tr -d \(, |awk '{print $3" "$4}' |while read fsname fstype
    do
      echo -n "{\"{#FSNAME}\":\"$fsname\", \"{#FSTYPE}\":\"$fstype\"},"
    done |sed -e 's:},$:}]}:'
}

function fsData {
  for i in $(mount |grep -w -E 'ufs' |tr -d \(, |awk '{print $3}')
    do
      df -k $i |tail -n 1|awk '{print $2" "$3" "$5}' |while read total used pused
        do
          echo "vfs.fs.size[$i,total] $total" 
          echo "vfs.fs.size[$i,used] $used"
          echo "vfs.fs.size[$i,pused] $pused" |tr -d %
        done
    done
}

function streamingDiscovery {
  replica_list=$(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication" 2>/dev/null)
  echo -n '{"data":['
  if [[ -n $replica_list ]];
    then 
      for replica in $replica_list; do echo -n "{\"{#HOTSTANDBY}\": \"$replica\"},"; done |sed -e 's:},$:}]}:'
    else
      echo ']}'
  fi
}

function streamingLagBytes {
  for i in $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication");
    do 
      echo -n "pgsql.streaming.lag[$i] "; 
      echo $(psql -qAtX postgres -c "select pg_xlog_location_diff(sent_location, replay_location) from pg_stat_replication where client_addr = '$i'")
    done
}

function streamingLagSeconds {
  for i in $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication");
    do 
      echo -n "pgsql.streaming.lag.seconds[$i] ";
      echo $(psql -h $i -qAtX postgres -c "select extract(epoch from now() - pg_last_xact_replay_timestamp())" || echo ZBX_NOTSUPPORTED)
    done
}

function iostatDiscovery() {
  echo -n '{"data":['
    for i in $(sysctl -n kern.disks); do echo -n "{\"{#HARDDISK}\": \"$i\"},"; done |sed -e 's:},$:}]}:'
}

function iostatCollect() {
  iostat -x -c 5 > /tmp/iostat.tmp 
}

function getUtilization() {
  grep -w $1 /tmp/iostat.tmp |awk -v N=8 'BEGIN {sum=0.0;count=0;} {sum=sum+$N;count=count+1;} END {printf("%.2f\n", sum/count);}'
}

function inventoryDisks {
  local diskData
  for disk in $(sysctl -n kern.disks); 
    do
      size=$(gpart show -l $disk 2>/dev/null |head -n 1 |grep -oE '\(.*\)' |tr -d \(\))
      if [[ -n $size ]]
        then diskData="$disk size ${size}, $diskData"
        else diskData="$disk size unknown, $diskData"
      fi
    done
  diskData=$(echo $diskData |sed -e 's/,$//')
  echo $diskData
}

function daily() {
# inventory
  echo "inventory.cpu.count $(sysctl -n hw.ncpu)"
  echo "inventory.cpu.model $(sysctl -n hw.model |xargs echo)"
  storageModel=$(pciconf -lv |grep -B3 -E 'subclass.*(RAID|SCSI)' |grep -E 'vendor|device' |awk -F= '{print $2}' |tr -d \' |xargs echo)
  [[ -n $storageModel ]] && echo "inventory.storage.model $storageModel" || echo "inventory.storage.model Unknown"
  echo -n "inventory.disks "; inventoryDisks
  echo "inventory.os $(uname -rps)"
  echo "inventory.kernel $(uname -i)"
  echo "inventory.hostname $(uname -n)"
  echo "inventory.pkg.pgbouncer $(pgbouncer -V 2>/dev/null |cut -d" " -f3)"
  echo "inventory.pkg.postgresql $($(ps -U pgsql -U pgsql -o command |grep -E "(postgres|postmaster).* -D" |grep -v grep |cut -d' ' -f1 |head -n 1) -V |cut -d" " -f3)"
# system
  echo "system.ram.total $(sysctl -n hw.physmem)"
  echo "system.swap.total $(swapinfo -k |tail -1 |awk '{sum += $2} END {print sum * 1024}')"
}

function hourly() {
echo -n "pgsql.streaming.discovery "; streamingDiscovery
echo -n "vfs.fs.discovery "; fsDiscovery
echo -n "iostat.discovery "; iostatDiscovery
for i in $pgGucs; do echo pgsql.setting[$i] $(psql -qAtX postgres -c "SELECT current_setting('$i')"); done
}

function always() {
iostatCollect
for i in $(sysctl -n kern.disks); do echo -n "disk.util[$i] "; getUtilization $i |tr , .; done
echo "system.localtime $(date +%s)"
sysctl -n vm.loadavg |tr -d {} |while read load1 load5 load15; do
  echo "system.load1 $load1" |tr , .
  echo "system.load5 $load5" |tr , .
  echo "system.load15 $load15" |tr , .
done
top -b -d 2 -s 1 |grep '^CPU:' |tail -n 1 |grep -oE '[0-9\.]+' |xargs echo |while read us ni sy itr id; do
  echo "system.cpu.user $us" |tr -d % |tr , .
  echo "system.cpu.sys $sy" |tr -d %  |tr , .
  echo "system.cpu.nice $ni" |tr -d % |tr , .
  echo "system.cpu.idle $id" |tr -d % |tr , .
done
echo "system.ram.free $(( $(sysctl -n vm.stats.vm.v_free_count) * $(sysctl -n hw.pagesize) ))"
echo "system.swap.free $(swapinfo -k |tail -1 |awk '{sum += $4} END {print sum * 1024}')"
fsData
# postgres
echo "pgsql.streaming.state $(psql -qAtX postgres -c 'SELECT pg_is_in_recovery()' 2>/dev/null ||echo ZBX_NOTSUPPORTED)"
echo "pgsql.streaming.count $(psql -qAtX postgres -c 'SELECT count(*) FROM pg_stat_replication' 2>/dev/null ||echo ZBX_NOTSUPPORTED)"
[[ $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication" 2>/dev/null) ]] && streamingLagBytes
[[ $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication" 2>/dev/null) ]] && streamingLagSeconds
echo "pgsql.connections[total] $(psql -qAtX postgres -c 'SELECT count(*) FROM pg_stat_activity' 2>/dev/null ||echo ZBX_NOTSUPPORTED)"
echo "proc.num[pgbouncer] $(ps ax |grep pgbouncer |grep -v grep |wc -l |xargs echo)"
echo "proc.num[postgres] $(ps x |grep postgres |grep -v grep |wc -l |xargs echo)"
echo "pgsql.connections[maxtime] $(psql -qAtX postgres -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where state <> 'idle' and query not like '%autovacuum%'")"
# 9.1 and older
# echo "pgsql.connections[maxtime] $(psql -qAtX postgres -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where current_query not like '%autovacuum%' and current_query not like '%IDLE%'")"
}

function main() {
case $PARAM in
'daily' ) daily ;;
'hourly' ) hourly ;;
'always' ) always ;;
esac
}

main
