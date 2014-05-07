#!/usr/bin/env bash
# Perform basebackup validation, version 0.4

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
COMPANY="company"
PARAMS=$@

trap scriptExit SIGINT SIGTERM

scriptExit() { 
  [[ -n $CLUSTERDIR ]] && rm -rf $CLUSTERDIR/
  rm $VALIDATION_LOCK
  exit 1
}

usage () {
  echo "${0##*/} usage: "
  echo " --backup=     basebackup directory or compressed file, supported: gzip, bzip2. (required)
 --wal=        directory which contains WAL archives (optional)
 --sandbox=    temp sandbox directory (required)
 --mailto=     send notify to email adrdesses (optional)

Example:
 ${0##*/} --backup=/var/tmp/backup.tar.bz2 --sandbox=/var/tmp/backup-test --mailto=ivanov@example.com,petrov@example.com"
}

getConfig() {
  local lkey=$1
  echo "$PARAMS" |sed -e 's:--:\n:g' |while read line; do echo $line |grep -P -w "$lkey=.*" |cut -d= -f2 |sed -e 's: $::'; done
}

sanityCheck() {
  [[ $(which pg_ctl) ]] && PG_CTL=$(which pg_ctl) || { echo "FATAL: pg_ctl not found. Exit."; exit 1; }
  [[ $(which find) ]] && FIND=$(which find) || { echo "FATAL: find not found. Exit."; exit 1; }
  [[ $(which nice) ]] && NICE="$(which nice) -n 19"
  [[ $(which ionice) ]] && IONICE="$(which ionice) -c 3"
  [[ $(which mail) ]] && MAIL=$(which mail) || echo "WARNING: mail not found, mail notification will not work."
  [[ -z $PARAMS ]] && { echo "${0##*/}: parameters is not specified."; usage; exit 1; }
  [[ -z $BACKUP ]] && { echo "${0##*/}: basebackup directory or archive is not specified."; usage; exit 1; }
  [[ -e $BACKUP ]] || { echo "${0##*/}: specified basebackup does not exists. Exit."; exit 1; }
  [[ -z $SANDBOXDIR ]] && { echo "${0##*/}: sandbox directory is not specified."; usage; exit 1; }
  [[ -f $CLONEPG_LOCK ]] && { echo "Basebackup performs. Exit."; exit 1; }
  [[ -f $VALIDATION_LOCK ]] && { echo "Another validation running or previous validation crash uncleanly. Exit."; exit 1; }
  [[ -d $SANDBOXDIR ]] || mkdir $SANDBOXDIR
}

prepareSandbox() {
  type=$(file $BACKUP |awk '{print $2}')
  case $type in
    directory ) rsync -a $BACKUP/ $SANDBOXDIR/ ;;
    gzip ) tar xzf $BACKUP -C $SANDBOXDIR/ ;;
    bzip2 ) lbunzip2 -d -n 6 < $BACKUP |tar xf - -C $SANDBOXDIR/ ;;
#    bzip2 ) tar xjf $BACKUP -C $SANDBOXDIR/ ;;
    * ) echo "${0##*/}: FATAL: unknown archive type. Supported types are: gzip,bzip2,directory."; exit 1 ;;
  esac
}

checkPgVersion() {
  [[ -f $PG_VERSION_FILE ]] || { echo "FATAL: PG_VERSION not found in backup, can't determine PostgreSQL version. Exit."; scriptExit; }
  local backupPgVersion=$(cat $PG_VERSION_FILE |cut -d. -f1,2 |tr -d .)
  local currentPgVersion=$(pg_config |awk '/VERSION/{ print $4 }' |cut -d. -f1,2 |tr -d .)
  [[ $currentPgVersion -ne $backupPgVersion ]] && { echo "FATAL: PostgreSQL installed version and backup version does not match. Exit."; exit 1; }
}

generateConfig() {
local maxConnections=$(pg_controldata $CLUSTERDIR |grep '^Current max_connections setting:' |awk '{print $4}')
local maxPreparedTransactions=$(pg_controldata $CLUSTERDIR |grep '^Current max_prepared_xacts setting:' |awk '{print $4}')
local maxLocksPerTransaction=$(pg_controldata $CLUSTERDIR |grep '^Current max_locks_per_xact setting:' |awk '{print $4}')
local walLevel=$(pg_controldata $CLUSTERDIR |grep '^Current wal_level setting:' |awk '{print $4}')

if [[ -n $WALDIR ]]; then
  cat > $CLUSTERDIR/recovery.conf << EOF
restore_command = 'cp $WALDIR/"%f" "%p"'
EOF
else
  cat > $CLUSTERDIR/recovery.conf << EOF
restore_command = 'exit 0'
EOF
rm $CLUSTERDIR/backup_label
fi

  cat > $CLUSTERDIR/postgresql.conf << EOF
listen_addresses = '127.0.0.1'
port = 25432
max_connections = ${maxConnections:-100}
max_prepared_transactions = ${maxPreparedTransactions:-0}
max_locks_per_transaction = ${maxLocksPerTransaction:-128}
wal_level = ${walLevel:-hot_standby}
shared_buffers = 64MB
wal_buffers = 32MB
checkpoint_segments = 32
hot_standby = on
unix_socket_directory = '/tmp'
EOF

  cat > $CLUSTERDIR/pg_hba.conf << EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
EOF

  touch $CLUSTERDIR/pg_ident.conf
}

runPostgres() {
  [[ -d $CLUSTERDIR/pg_xlog ]] || mkdir $CLUSTERDIR/pg_xlog
  [[ -d $CLUSTERDIR/pg_stat_tmp ]] || mkdir $CLUSTERDIR/pg_stat_tmp
  chmod 700 $CLUSTERDIR
  $PG_CTL -D $CLUSTERDIR start -l $PGLOG
}

checkPostgres() {
  local interval=60
  local try=10
  local response
  for i in $(seq 0 $try); do
    echo "debug: try is $i"
    response=$(psql -qAtX -h 127.0.0.1 -p 25432 -c "SELECT pg_is_in_recovery()::int" -U postgres postgres)
    [[ $response == 0 || $i == $try ]] && break
    echo "debug: perform sleep"
    sleep $interval
  done
  [[ $response == 0 ]] && PG_STATUS="successful" || PG_STATUS="failed"
}

sendNotify() {
  if [ -z $MAILTO ]; then MAILTO="/dev/null"; fi
  tail -n 15 $PGLOG |$MAIL -e -s "$PG_STATUS basebackup validation on $COMPANY for $BACKUP at $(date +\%d-\%b-\%Y)" $(echo $MAILTO |sed -e "s/,/ /g")
}

stopPostgres() {
  $PG_CTL -D $CLUSTERDIR -m fast stop
  rm -rf $SANDBOXDIR/
}

main() {
  BACKUP=$(getConfig backup)
  SANDBOXDIR=$(getConfig sandbox)
  WALDIR=$(getConfig wal)
  MAILTO=$(getConfig mailto)
  CLONEPG_LOCK="/tmp/clonepg.lock"
  VALIDATION_LOCK="/tmp/${BACKUP##*/}-validation.lock"

  sanityCheck
  touch $VALIDATION_LOCK 
  prepareSandbox
  
  PG_VERSION_FILE=$($NICE $IONICE $FIND $SANDBOXDIR -type f -size -16c -name PG_VERSION |sort -r |head -n 1)
  CLUSTERDIR=${PG_VERSION_FILE%/*}
  
  checkPgVersion
  generateConfig

  PGLOG="$CLUSTERDIR/postgresql.log"

  runPostgres

  PG_STATUS=0
  checkPostgres
  sendNotify
  stopPostgres
  rm $VALIDATION_LOCK
}

main
