#!/usr/bin/env bash
# Description:	some cool descr here...
# params: print only, or send

company="1+1"
export PATH="/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin"

PARAM="$@"

getData() {
  cpuModel=$(awk -F: '/^model name/ {print $2; exit}' /proc/cpuinfo)
  cpuCount=$(awk -F: '/^physical id/ { print $2 }' /proc/cpuinfo |sort -u |wc -l)
  cpuData="$cpuCount x $cpuModel"

  memTotal=$(awk -F: '/^MemTotal/ {print $2}' /proc/meminfo |xargs echo)
  swapTotal=$(awk -F: '/^SwapTotal/ {print $2}' /proc/meminfo |xargs echo)
  memData="physical memory: $memTotal; swap: $swapTotal"

  # required lspci for pci device_id and vendor_id translation
  storageData=$(lspci |awk -F: '/storage controller/ || /RAID/ { print $3 }' |xargs echo)

  for disk in $(grep -Ewo '[s,h,v]d[a-z]' /proc/partitions |sort -r |xargs echo); do
    size=$(echo $(($(cat /sys/dev/block/$(grep -w $disk /proc/partitions |awk '{print $1":"$2}')/size) * 512 / 1024 / 1024 / 1024)))
    diskData="$disk size ${size}GiB, $diskData"
  done
  diskData=$(echo $diskData |sed -e 's/,$//')

  # required lspci for pci device_id and vendor_id translation
  netData=$(lspci |awk -F: '/Ethernet controller/ {print $3}' |xargs echo)

  hostname=$(uname -n)
  os=$(lsb_release -d 2>/dev/null |awk -F: '{print $2}' |xargs echo)
  kernel=$(uname -sr)
  ip=$(ip address list |grep -oE "inet [0-9]{1,3}(\.[0-9]{1,3}){3}" |awk '{ print $2 }' |grep -vE '^(127|10|172.(1[6-9]{1}|2[0-9]{1}|3[0-2]{1})|192\.168)\.' |xargs echo)

  pgVersion=$($(ps h -o cmd -C postgres |grep "postgres -D" |cut -d' ' -f1) -V |cut -d" " -f3)
  pgbVersion=$(pgbouncer -V 2>/dev/null |cut -d" " -f3)
  pgDatabases=$(psql -ltXAF: -U postgres -c "\l+" |awk -F: '{print $1" ("$7", "$3", "$4");"}' |grep -vE 'template|postgres' |xargs echo |sed -e 's/;$/\./g')
  pgReplicaCount=$(psql -ltXAF: -U postgres -c "select count(*) from pg_stat_replication")
  pgRecoveryStatus=$(psql -ltXAF: -U postgres -c "select pg_is_in_recovery()")
}

printData() {
  echo "Cpu:               $cpuData
Memory:            $memData
Storage:           $storageData
Disks:             $diskData
Network:           $netData
System:            $hostname ($ip); $os; $kernel
PostgreSQL ver.:   $pgVersion (recovery: $pgRecoveryStatus, replica count: $pgReplicaCount)
pgBouncer ver.:    $pgbVersion
PostgreSQL databases: $pgDatabases"
}

sendData() {
  pgDestHost=$(echo $PARAM |grep -oiP "host=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestPort=$(echo $PARAM |grep -oiP "port=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestDb=$(echo $PARAM |grep -oiP "database=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestUser=$(echo $PARAM |grep -oiP "user=[a-z0-9\-\._]+" |cut -d= -f2)
  pgOpts="-h ${pgDestHost:-127.0.0.1} -p ${pgDestPort:-5432} -U ${pgDestUser:-postgres}"

  # new send with upsert
  psql $pgOpts -c "BEGIN;
    WITH upsert AS
    (
      UPDATE servers SET updated_at=now(),is_alive=true WHERE hostname='$hostname' RETURNING *
    )
    INSERT INTO servers (company,hostname,updated_at) 
    SELECT '$company','$hostname',now() WHERE NOT EXISTS
    (
      SELECT hostname FROM upsert WHERE hostname='$hostname'
    );
    WITH upsert AS
    (
      UPDATE hardware SET cpu='$cpuData',memory='$memData',network='$netData',storage='$storageData',disks='$diskData' WHERE hostname='$hostname' RETURNING *
    )
    INSERT INTO hardware (hostname,cpu,memory,network,storage,disks)
    SELECT '$hostname','$cpuData','$memData','$netData','$storageData','$diskData' WHERE NOT EXISTS
    (
      SELECT hostname FROM hardware WHERE hostname='$hostname'
    );
    WITH upsert AS
    (
      UPDATE software SET os='$os',ip='$ip',kernel='$kernel',pg_version='$pgVersion',pgb_version='$pgbVersion',databases='$pgDatabases' WHERE hostname='$hostname' RETURNING *
    )
    INSERT INTO software (hostname,os,ip,kernel,pg_version,pgb_version,databases) 
    SELECT '$hostname','$os','$ip','$kernel','$pgVersion','$pgbVersion','$pgDatabases' WHERE NOT EXISTS
    (
      SELECT hostname FROM software WHERE hostname='$hostname'
    );
    COMMIT;" ${pgDestDb:-scrapper}
}

main() {
  case "$PARAM" in
  --print-only )
     getData
     printData
  ;;
  --send=* )
     getData
     sendData
  ;;
  --usage|--help|* )
     echo "${0##*/} usage: 
--print-only	only print data;
--send=a:b:c:d	send data to a remote server with the specified address(a), port(b), database(c) and user(d);
--usage,--help	print this message.

Example:	${0##*/} --send=1.2.3.4:5432:db:user"
  esac
}

main
