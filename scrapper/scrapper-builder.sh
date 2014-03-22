#!/usr/bin/env bash
# Description:	some cool description here

PARAM="$@"

buildHtml() {
  pgDestHost=$(echo $PARAM |grep -oiP "host=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestPort=$(echo $PARAM |grep -oiP "port=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestDb=$(echo $PARAM |grep -oiP "database=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestUser=$(echo $PARAM |grep -oiP "user=[a-z0-9\-\._]+" |cut -d= -f2)
  pgOpts="-h ${pgDestHost:-127.0.0.1} -p ${pgDestPort:-5432} -U ${pgDestUser:-scrapper}"

echo "$pgOpts"

companyList=$(psql -qAtX $pgOpts -c "select distinct(company) from servers" $pgDestDb |xargs echo)

for company in $companyList; do
  # build company header
  echo "<table border="1">"
  echo "<caption> $company </caption>"
  
  # build server title
  echo "<tr><th>Hostname</th><th>IP</th><th>CPU</th><th>Memory</th><th>Storage</th><th>Disks</th><th>Network</th><th>Operating system</th><th>Kernel</th><th>PostgreSQL version</th><th>PgBouncer version</th><th>Databases</th></tr>"

  # build server rows
  serverList=$(psql -qAtX $pgOpts -c "select c.company,c.hostname,s.ip,h.cpu,h.memory,h.storage,h.disks,h.network,s.os,s.kernel,s.pg_version,s.pgb_version,s.databases from servers c join hardware h on c.hostname = h.hostname join software s on c.hostname = s.hostname where company = '$company'" $pgDestDb)
  echo "$serverList" |while read server; do
    SAVEIFS=$IFS ; IFS='|'
    echo "$server" |while read company hostname ip cpu memory storage disks network os kernel pgversion pgbversion databases; do
     echo "<tr><td>$hostname</td><td>$ip</td><td>$cpu</td><td>$memory</td><td>$storage</td><td>$disks</td><td>$network</td><td>$os</td><td>$kernel</td><td>$pgversion</td><td>$pgbversion</td><td>$databases</td></tr>"
    done
  done
  IFS=$SAVEIFS
  # close table
  echo "</table>"
done
}

main() {
  case "$PARAM" in
    --build=* ) buildHtml ;;
    --usage|--help|* ) usage ;;
  esac
}

main
