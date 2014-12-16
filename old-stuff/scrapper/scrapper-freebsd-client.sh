#!/usr/local/bin/bash
# Description:  some cool descr here...
# params: print only, or send

company="1+1"
psqlCmd="psql -tXAF: -U pgsql"
export PATH="/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin"

PARAM="$@"

usage () {
   echo "${0##*/} usage: "
   echo "  --print-human         get server information and print it in human readable format.
  --print-sql           get server information and print raw SQL.
  --help,--usage,-h     print this help."
}

getData() {
  cpuModel=$(sysctl -n hw.model)
  coreCount=$(sysctl -n hw.ncpu)
  cpuData="$cpuModel ($coreCount cores)"

  memTotal=$(echo $(($(sysctl -n hw.physmem) / 1024)))
  swapTotal=$(swapinfo -k |tail -1 |awk '{sum += $2} END {print sum}')
  memData="physical memory: $memTotal kB; swap: $swapTotal kB"

  # required lspci for pci device_id and vendor_id translation
  storageData=$(pciconf -lv |grep -B3 -E 'subclass.*(RAID|SCSI)' |grep -E 'vendor|device' |awk -F= '{print $2}' |tr -d \' |xargs echo)

  for disk in $(sysctl -n kern.disks); do
    size=$(gpart show -l $disk 2>/dev/null |head -n 1 |grep -oE '\(.*\)' |tr -d \(\))
    if [[ -n $size ]]
      then diskData="$disk size ${size}, $diskData"
      else continue
    fi
  done
  diskData=$(echo $diskData |sed -e 's/,$//')

  # required lspci for pci device_id and vendor_id translation
  netData=$(pciconf -lv |grep -B2 -E 'subclass.*ethernet' |grep -E 'device' |awk -F= '{print $2}' |tr -d \' |uniq -c |xargs echo)

  hostname=$(uname -n)
  os=$(uname -rps)
  kernel=$(uname -i)
  ip=$(ifconfig |grep -oE "inet [0-9]{1,3}(\.[0-9]{1,3}){3}" |awk '{ print $2 }' |grep -vE '^(127|10|172.(1[6-9]{1}|2[0-9]{1}|3[0-2]{1})|192\.168)\.' |xargs echo)

  pgGetDbQuery="SELECT d.datname as name,
                       pg_catalog.pg_encoding_to_char(d.encoding) as encoding,
                       d.datcollate as collate,d.datctype as ctype,
                       CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
                            THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
                            ELSE 'No Access'
                       END as size 
                FROM pg_catalog.pg_database d 
                JOIN pg_catalog.pg_tablespace t on d.dattablespace = t.oid 
                ORDER BY 1;"
  pgVersion=$($(ps -U pgsql -U postgres -o command |grep -E "(postgres|postmaster).* -D" |grep -v grep |head -n 1 |cut -d' ' -f1) -V |cut -d" " -f3)
  pgbVersion=$(pgbouncer -V 2>/dev/null |cut -d" " -f3)
  pgDatabases=$($psqlCmd -c "$pgGetDbQuery" |awk -F: '{print $1" ("$5", "$2", "$3");"}' |grep -vE 'template|postgres' |xargs echo |sed -e 's/;$/\./g')
  pgReplicaCount=$($psqlCmd -c "select count(*) from pg_stat_replication")
  pgRecoveryStatus=$($psqlCmd -c "select pg_is_in_recovery()")
}

printHuman() {
  echo "Cpu:               $cpuData
Memory:            $memData
Storage:           $storageData
Disks:             $diskData
Network:           $netData
System:            $hostname ($ip); $os; kernel $kernel
PostgreSQL ver.:   $pgVersion (recovery: $pgRecoveryStatus, replica count: $pgReplicaCount)
pgBouncer ver.:    $pgbVersion
PostgreSQL databases: $pgDatabases"
}

printSql() {
  # new send with upsert
  echo "BEGIN;
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
      UPDATE software SET os='$os',ip='$ip',kernel='$kernel',pg_version='PostgreSQL ver.: $pgVersion (recovery: $pgRecoveryStatus, replica count: $pgReplicaCount)',pgb_version='pgBouncer ver.: $pgbVersion',databases='$pgDatabases' WHERE hostname='$hostname' RETURNING *
    )
    INSERT INTO software (hostname,os,ip,kernel,pg_version,pgb_version,databases) 
    SELECT '$hostname','$os','$ip','$kernel','PostgreSQL ver.: $pgVersion (recovery: $pgRecoveryStatus, replica count: $pgReplicaCount)','pgBouncer ver.: $pgbVersion','$pgDatabases' WHERE NOT EXISTS
    (
      SELECT hostname FROM software WHERE hostname='$hostname'
    );
    COMMIT;"
}

main() {
  case "$PARAM" in
  --print-human )
     getData
     printHuman
  ;;
  --print-sql )
     getData
     printSql
  ;;
 --usage|--help|* )
     usage
  ;;
  esac
}

main
