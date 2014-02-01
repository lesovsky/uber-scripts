#!/usr/bin/env bash
# Description:	some cool descr here...
# params: print only, or send

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
  storageData=$(lspci |awk -F: '/storage controller/ { print $3 }')

  for disk in $(grep -Ewo '[s,h,v]d[a-z]' /proc/partitions); do
    num=$(awk '/$disk/ {print $1":"$2; exit}' /proc/partitions)
    size=$(echo $(($(cat /sys/dev/block/$(awk '/sda/ {print $1":"$2; exit} ' /proc/partitions)/size) * 512 / 1024 / 1024 / 1024)))
    diskData="$disk size ${size}GiB"
  done

  # required lspci for pci device_id and vendor_id translation
  netData=$(lspci |awk -F: '/Ethernet controller/ {print $3}' |xargs echo)

  hostname=$(uname -n)
  os=$(lsb_release -d 2>/dev/null |awk -F: '{print $2}' |xargs echo)
  kernel=$(uname -sr)

  pgVersion=$($(ps h -o cmd -C postgres |grep "postgres -D" |cut -d' ' -f1) -V |cut -d" " -f3)
  pgbVersion=$(pgbouncer -V 2>/dev/null |cut -d" " -f3)
  pgDatabases=$(psql -ltAF: -l -U postgres |cut -d: -f1 |grep -vE 'template|postgres')
}

printData() {
  echo "Cpu:               $cpuData
Memory:            $memData
Storage:           $storageData
Disks:             $diskData
Network:           $netData
System:            $hostname; $os; $kernel
PostgreSQL ver.:   $pgVersion
pgBouncer ver.:    $pgbVersion
PostgreSQL databases: $pgDatabases"
}

sendData() {
  pgDestHost=$(echo $PARAM |cut -d= -f2 |cut -d: -f1)
  pgDestPort=$(echo $PARAM |cut -d= -f2 |cut -d: -f2)
  pgDestUser=$(echo $PARAM |cut -d= -f2 |cut -d: -f3)
  pgDestDb=$(echo $PARAM |cut -d= -f2 |cut -d: -f4)
  pgOpts="-h $pgDestHost -p $pgDestPort -U $pgDestUser"

  # send ...
  psql $pgOpts -c "INSERT INTO servers (company,hostname,updated_at) VALUES ('MBT','$hostname',now())" $pgDestDb
  psql $pgOpts -c "INSERT INTO hardware (hostname,cpu,memory,network,storage,disks) VALUES ('$hostname','$cpuData','$memData','$netData','$storageData','$diskData')" $pgDestDb
  psql $pgOpts -c "INSERT INTO software (hostname,os,kernel,pg_version,pgb_version,databases) VALUES ('$hostname','$os','$kernel','$pgVersion','$pgbVersion','$pgDatabases')" $pgDestDb
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
--send=a:b:c:d	send data to a remote server with the specified address(a), port(b), user(c) and database(d);
--usage,--help	print this message.

Example:	${0##*/} --send=1.2.3.4:5432:user:db"
  esac
}

main
