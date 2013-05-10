#!/usr/bin/env bash
# Perform basebackup validation

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PG_CTL=$(which pg_ctl)
CLONEPG_LOCK="/tmp/clonepg.lock"
VALIDATION_LOCK="/tmp/basebackup-validation.lock"

usage (){
echo "basebackup-validation.sh usage: "
echo " -t, --target 	basebackup directory (required)"
echo " -s, --sandbox	temp sandbox directory (required)"
echo " -m, --mailto	send notify to email adrdesses (optional)"
}

if [ "$#" -eq 0 ]; then echo "basebackup-validation.sh: parameters is not specified"; usage; exit; fi
if ! grep -qE '\-t=|\-\-target=' <<< $@ ; then echo "basebackup-validation.sh: basebackup is not specified."; usage; exit; fi
if ! grep -qE '\-s=|\-\-sandbox=' <<< $@ ; then echo "basebackup-validation.sh: sandbox is not specified."; usage; exit; fi

for param in "$@"
  do
    case $param in
      -t=*|--target=*)
      TARGETDB=$(echo $param | sed 's/[-a-zA-Z0-9]*=//')
      ;;
      -s=*|--sandbox=*)
      SANDBOXDIR=$(echo $param | sed 's/[-a-zA-Z0-9]*=//')
      PGLOG="$SANDBOXDIR/logfile"
      ;;
      -m=*|--mailto=*)
      MAILTO=$(echo $param | sed 's/[-a-zA-Z0-9]*=//')
      ;;
      *)      
      echo "basebackup-validation.sh: unknown parameter specified."; usage; exit
      ;;
    esac
done

if [ -f $CLONEPG_LOCK ]; then echo "Basebackup performs. Exit."; exit 1; fi
if [ -f $VALIDATION_LOCK ]; then echo "Another validation running or previous validation crash uncleanly. Exit."; exit 1; fi
if [ ! -d $SANDBOXDIR ]; then mkdir $SANDBOXDIR; fi

rsync -a $TARGETDB/ $SANDBOXDIR/

cat > $SANDBOXDIR/recovery.conf << EOF
restore_command = 'cp /opt/pgsql/pgbackup/archive/%f "%p"'
EOF

cat > $SANDBOXDIR/postgresql.conf << EOF
listen_addresses = '127.0.0.1'
port = 9876
max_connections = 100
shared_buffers = 128MB
wal_level = hot_standby
checkpoint_segments = 3
hot_standby = on
EOF

cat > $SANDBOXDIR/pg_hba.conf << EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
EOF

touch $SANDBOXDIR/pg_ident.conf

# start test postgres
$PG_CTL -D $SANDBOXDIR start -l $PGLOG

# analyze log
tail -fn0 $PGLOG | while read line ; do
  echo "$line" | grep -E "database system is ready to accept connections|FATAL"
  if [ $? = 0 ]; then
    echo "database validation finished."
    if [ -z $MAILTO ]; then MAILTO="/dev/null"; fi
    tail -n 22 $PGLOG |mail -e -s "basebackup validation for $LATEST" $(echo $MAILTO |sed -e "s/,/ /g")
    killall tail
  fi
done

# stop and remove temp postgres
$PG_CTL -D $SANDBOXDIR stop
rm -rf $SANDBOXDIR/*
