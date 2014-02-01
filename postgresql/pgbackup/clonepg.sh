#!/usr/bin/env bash
# Create basebackup of postgresql server cluster and perform validation if required.
# Make sure that you can connect to the postgres
# Script perform remove old basebackup copies older then $AGE period 

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PG_BASEBACKUP=$(which pg_basebackup)
PG_ARCHIVECLEANUP=$(which pg_archivecleanup)
CURRENT="db-$(date +%m-%d-%Y_%H)"
AGE="-atime +3"
LOCK="/tmp/clonepg.lock"

usage (){
echo "clonepg.sh usage: "
echo " -b, --backupdir     backupdir, basebackup destination (required)"
echo " -v, --validate      sanbox, perform validate with basebackup-validation.sh in specified sandbox (optional)"
echo " -m, --mailto        mail addresses, send logfile to specified emails (optional)"
}

# perform sanity checks, check options.
if [ "$#" -eq 0 ]; then echo "clonepg.sh: parameters is not specified."; usage; exit; fi
if ! grep -qE '\-b=|\-\-backupdir=' <<< $@
  then echo "clonepg.sh: backupdir parameter is not specified."; usage; exit; 
fi

# processing parameters
for param in "$@"
  do
    case $param in
      -b=*|--backupdir=*)
      BACKUPDIR=$(echo $param | sed 's/[-a-zA-Z0-9]*=//')
      ;;
      -v=*|--validate=*)
      VALIDATE=$(echo $param | sed 's/[-a-zA-Z0-9]*=//')
      ;;
      -m=*|--mailto=*)
      MAILTO=$(echo $param | sed 's/[-a-zA-Z0-9]*=//')
      ;;
      *)
      echo "clonepg.sh: unknown parameter specified."; usage; exit
     ;;
    esac
  done

# Main 
if [ -f $LOCK ]; 
   then echo "Another pg_basebackup is running. Quit."; exit 1;
fi

touch $LOCK
mkdir $BACKUPDIR/$CURRENT

$PG_BASEBACKUP -l "basebackup $(date +%m-%d-%Y_%H)" -U postgres -D $BACKUPDIR/$CURRENT
chmod 700 $BACKUPDIR/$CURRENT

# remove old backups
/usr/bin/find $BACKUPDIR -maxdepth 1 -type d $AGE -name "db-*" |xargs rm -rf
for backup_label in $(find $BACKUPDIR/archive/*.backup $AGE -exec basename {} \;)
  do
    $PG_ARCHIVECLEANUP $BACKUPDIR/archive/ $backup_label
    rm $BACKUPDIR/archive/$backup_label
  done

rm $LOCK

# start validation if specified
if [ ! -z "$VALIDATE" ]; then
  echo "validate enabled. start validation."
  if [ -z $MAILTO ]; then MAILTO="/dev/null"; fi 
  ~postgres/bin/basebackup-validation.sh --backup=$BACKUPDIR/$CURRENT --sandbox=$VALIDATE --mailto=$MAILTO
fi
