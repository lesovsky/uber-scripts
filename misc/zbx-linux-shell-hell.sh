#!/usr/bin/env bash
# Description:  Get various data an print it to stdout.
# Author:       Lesovsky A.V.           Revision:       0.1

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
pgGucs="fsync synchronous_commit full_page_writes max_connections"
PARAM=$1

function fsDiscovery {
  echo -n '{"data":['
  grep -w -E 'ext(3|4)|reiserfs|xfs' /proc/mounts |awk '{print $2" "$3}' |while read fsname fstype
    do
      echo -n "{\"{#FSNAME}\":\"$fsname\", \"{#FSTYPE}\":\"$fstype\"},"
    done |sed -e 's:\},$:\}:'
  echo ']}'
}

function fsData {
  for i in $(grep -w -E 'ext(3|4)|reiserfs|xfs' /proc/mounts |awk '{print $2}')
    do
      df -P $i 2>/dev/null |tail -n 1|awk '{print $2" "$3" "$5}' |while read total used pused
        do
          echo "vfs.fs.size[$i,total] $total"
          echo "vfs.fs.size[$i,used] $used"
          echo "vfs.fs.size[$i,pused] $pused" |tr -d %
        done
    done
}

function streamingDiscovery {
  replica_list=$(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication WHERE application_name <> 'pg_basebackup'")
  echo -n '{"data":['
  for replica in $replica_list; do echo -n "{\"{#HOTSTANDBY}\": \"$replica\"},"; done |sed -e 's:\},$:\}:'
  echo ']}'
}

function streamingLagBytes {
  for i in $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication WHERE application_name <> 'pg_basebackup'");
    do 
      echo -n "pgsql.streaming.lag[$i] ";
      echo $(psql -qAtX postgres -c "select pg_xlog_location_diff(sent_location, replay_location) from pg_stat_replication where client_addr = '$i'" || echo ZBX_NOTSUPPORTED)
    done
}

function streamingLagSeconds {
  for i in $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication WHERE application_name <> 'pg_basebackup'");
    do 
      echo -n "pgsql.streaming.lag.seconds[$i] ";
      echo $(psql -h $i -qAtX postgres -c "select extract(epoch from now() - pg_last_xact_replay_timestamp())" || echo ZBX_NOTSUPPORTED)
    done
}

function streamingPacketLoss {
  for i in $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication WHERE application_name <> 'pg_basebackup'");
    do 
      echo -n "icmppingloss[$i] ";
      echo $(ping -q -c 10 -i 0.2 $i |grep 'packet loss' |awk '{print $6}' |tr -d % || echo ZBX_NOTSUPPORTED)
    done
}

function iostatDiscovery() {
  echo -n '{"data":['
    for i in $(iostat -d |grep -w -E '^(xvd|sd|hd|vd)[a-z]' |awk '{print $1}'); do echo -n "{\"{#HARDDISK}\": \"$i\"},"; done |sed -e 's:\},$:\}:'
  echo ']}'
}

function iostatCollect() {
  DISK=$(iostat -x 1 10 | awk 'BEGIN {check=0;} {if(check==1 && $1=="avg-cpu:"){check=0}if(check==1 && $1!=""){print $0}if($1=="Device:"){check=1}}' | tr '\n' '|')
  echo $DISK | sed 's/|/\n/g' > /tmp/iostat.tmp
}

function getUtilization() {
  iostat -V &>/tmp/iostat.version
  iostatVersion=$(grep -oE '[0-9\.]+' /tmp/iostat.version |tr -d .)
  if [[ $iostatVersion -le 911 ]]; then utilField=12; else utilField=14; fi
  grep -w $1 /tmp/iostat.tmp | tail -n +2 | tr -s ' ' |awk -v N=$utilField 'BEGIN {sum=0.0;count=0;} {sum=sum+$N;count=count+1;} END {printf("%.2f\n", sum/count);}'
  rm /tmp/iostat.version
}

function inventoryStorage {
  [[ $(lspci 2>/dev/null) ]] && model=$(lspci |awk -F: '/storage controller/ || /RAID/ || /SCSI/ { print $3 }' |xargs echo)
  [[ -z $model ]] && echo unknown || echo $model
}

function inventoryDisks {
  local diskData
  for disk in $(grep -Ewo '[s,h,v]d[a-z]|c[0-9]d[0-9]' /proc/partitions |sort -r |xargs echo); 
    do
      size=$(echo $(($(cat /sys/dev/block/$(grep -w $disk /proc/partitions |awk '{print $1":"$2}')/size) * 512 / 1024 / 1024 / 1024)))
      diskData="$disk size ${size}GiB, $diskData"
    done;
  diskData=$(echo $diskData |sed -e 's/,$//')
  if [[ -n $diskData ]]; then echo $diskData; else echo unknown; fi  
}

function daily() {
# inventory
  echo "inventory.cpu.count $(awk -F: '/^physical id/ { print $2 }' /proc/cpuinfo |sort -u |wc -l)"
  echo "inventory.cpu.model $(awk -F: '/^model name/ {print $2; exit}' /proc/cpuinfo)"
  echo -n "inventory.storage.model "; inventoryStorage
  echo -n "inventory.disks "; inventoryDisks
  echo -n "inventory.os "; [[ $(which lsb_release 2>/dev/null) ]] && lsb_release -d |awk -F: '{print $2}' |xargs echo ||echo unknown
  echo "inventory.kernel $(uname -sr)"
  echo "inventory.hostname $(uname -n)"
  echo -n "inventory.pkg.pgbouncer "; [[ $(which pgbouncer 2>/dev/null) ]] && pgbouncer -V |cut -d" " -f3 || echo not installed
  echo "inventory.pkg.postgresql $($(ps h -o cmd -C postgres -C postmaster |grep -E "(postgres|postmaster).* -D" |cut -d' ' -f1 |head -n 1) -V |cut -d" " -f3)"
# system
  echo "system.ram.total $(grep -m 1 MemTotal: /proc/meminfo |awk '{ printf "%.0f\n", $2 * 1024 }')"
  echo "system.swap.total $(grep -m 1 SwapTotal: /proc/meminfo |awk '{ printf "%.0f\n", $2 * 1024 }')"
  echo "sysctl[fs.file-nr] $(sysctl fs.file-nr |awk '{print $3}')"
  echo "sysctl[vm.dirty_bytes] $(sysctl vm.dirty_bytes |awk '{print $3}')"
  echo "sysctl[vm.dirty_background_bytes] $(sysctl vm.dirty_background_bytes |awk '{print $3}')"
  echo "sysctl[vm.overcommit_memory] $(sysctl vm.overcommit_memory |awk '{print $3}')"
  echo "sysctl[vm.overcommit_ratio] $(sysctl vm.overcommit_ratio|awk '{print $3}')"
  echo "sysctl[vm.swappiness] $(sysctl vm.swappiness |awk '{print $3}')"
  echo "sysctl[vm.zone_reclaim_mode] $(sysctl vm.zone_reclaim_mode |awk '{print $3}')"
}

function hourly() {
echo -n "pgsql.streaming.discovery "; streamingDiscovery
echo -n "vfs.fs.discovery "; fsDiscovery
echo -n "iostat.discovery "; iostatDiscovery
for i in $pgGucs; do echo pgsql.setting[$i] $(psql -qAtX postgres -c "SELECT current_setting('$i')"); done
}

function always() {
iostatCollect
for i in $(iostat -d |grep -E '^(xvd|sd|hd|vd)[a-z]' |awk '{print $1}'); do echo -n "disk.util[$i] "; getUtilization $i; done
echo "system.localtime $(date +%s)"
while read load1 load5 load15 processes rcreated; do
  echo "system.load1 $load1"
  echo "system.load5 $load5"
  echo "system.load15 $load15"
done < /proc/loadavg
top -b -n 2 -d 0.2 |grep -E '^(%)?Cpu' |tail -n 1 |sed -e 's:%: :g' |grep -oE '[0-9\.]+' |xargs echo |while read us sy ni id wa hi si st; do
  echo "system.cpu.user $us"
  echo "system.cpu.sys $sy"
  echo "system.cpu.nice $ni"
  echo "system.cpu.idle $id"
  echo "system.cpu.wait $wa"
done
echo "system.ram.free $(grep -m 1 MemFree: /proc/meminfo |awk '{ printf "%.0f\n", $2 * 1024 }')"
echo "system.swap.free $(grep -m 1 SwapFree: /proc/meminfo |awk '{ printf "%.0f\n", $2 * 1024 }')"
fsData
# postgres
echo "pgsql.streaming.state $(psql -qAtX postgres -c 'SELECT pg_is_in_recovery()')"
echo "pgsql.streaming.count $(psql -qAtX postgres -c 'SELECT count(*) FROM pg_stat_replication')"
[[ $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication WHERE application_name <> 'pg_basebackup'" 2>/dev/null) ]] && streamingLagBytes 2>/dev/null
[[ $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication WHERE application_name <> 'pg_basebackup'" 2>/dev/null) ]] && streamingLagSeconds 2>/dev/null
[[ $(psql -qAtX postgres -c "SELECT client_addr FROM pg_stat_replication WHERE application_name <> 'pg_basebackup'" 2>/dev/null) ]] && streamingPacketLoss 2>/dev/null
echo "pgsql.connections[total] $(psql -qAtX postgres -c 'SELECT count(*) FROM pg_stat_activity' 2>/dev/null ||echo ZBX_NOTSUPPORTED)"
echo "pgsql.connections[maxtime] $(psql -qAtX postgres -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where state <> 'idle' and query not like '%autovacuum%'")"
# 9.1 and older
# echo "pgsql.connections[maxtime] $(psql -qAtX postgres -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where current_query not like '%autovacuum%' and current_query not like '%IDLE%'")"
echo "proc.num[pgbouncer] $(ps h -C pgbouncer |wc -l |xargs echo)"
echo "proc.num[postgres] $(ps h -C postgres -C postmaster |wc -l |xargs echo)"
}

function main() {
case $PARAM in
'daily' ) daily ;;
'hourly' ) hourly ;;
'always' ) always ;;
* ) echo "unknown param, use daily, hourly or always param" ;;
esac
}

main
