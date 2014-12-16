#!/usr/bin/env bash
# Description:	some cool description here

PARAM="$@"

buildHtml() {
  pgDestHost=$(echo $PARAM |grep -oiP "host=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestPort=$(echo $PARAM |grep -oiP "port=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestDb=$(echo $PARAM |grep -oiP "database=[a-z0-9\-\._]+" |cut -d= -f2)
  pgDestUser=$(echo $PARAM |grep -oiP "user=[a-z0-9\-\._]+" |cut -d= -f2)

companyList=$(psql -qAtX -h ${pgDestHost:-127.0.0.1} -p ${pgDestPort:-5432} -U ${pgDestUser:-scrapper} -c "select distinct(company) from servers" ${pgDestDb:-scrapper} |xargs echo)

for company in $companyList; do
  # build company header
echo "<head>
<style type="text/css">
<!--TD{font-family: Arial; font-size: 10pt;}--->
</style>
</head>
<table border='1' style='width:100%'>
     <caption><span style="font-weight:bold">$company</span></caption>"

  # build server rows
  serverList=$(psql -qAtX -h ${pgDestHost:-127.0.0.1} -p ${pgDestPort:-5432} -U ${pgDestUser:-scrapper} -c "select c.company,c.hostname,c.updated_at,s.ip,h.cpu,h.memory,h.storage,h.disks,h.network,s.os,s.kernel,s.pg_version,s.pgb_version,s.databases from servers c join hardware h on c.hostname = h.hostname join software s on c.hostname = s.hostname where is_alive = 't' and company = '$company'" ${pgDestDb:-scrapper})
  echo "$serverList" |while read server; do
    SAVEIFS=$IFS ; IFS='|'
    echo "$server" |while read company hostname updated_at ip cpu memory storage disks network os kernel pgversion pgbversion databases; do
    echo \
      "<col width='50%'>
      <col width='50%'>
      <tr bgcolor='#C80000'>
        <td>$hostname ($ip)</td>
        <td>$updated_at</td>
      </tr>
      <tr bgcolor='#FFCC99'>
        <td>$os $kernel</td>
        <td>$cpu</td>
      </tr>
      <tr bgcolor='#FFCC99'>
        <td>$pgversion</td>
        <td>$memory</td>
      </tr>
      <tr bgcolor='#FFCC99'>
        <td>$pgbversion</td>
        <td>$storage</td>
      </tr>
      <tr bgcolor='#FFCC99'>
        <td>$databases</td>
        <td>$disks</td>
      </tr>
      <tr bgcolor='#FFCC99'>
        <td></td>
        <td>$network</td>
      </tr>
    <tr></tr><tr></tr><tr></tr><tr></tr><tr></tr><tr></tr>"
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
