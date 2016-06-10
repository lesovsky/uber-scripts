#!/bin/bash
# Author:	Lesovsky A.V., lesovsky@pgco.me
# Description:	Backup patitions of previous month to Amazon S3

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
tablesList="versions feed_actions"
partition=$(date +%Y_%m -d '1 month ago')
tmpDir="/var/lib/postgresql/tmp"

[[ ! -d $tmpDir ]] && mkdir -p $tmpDir

for table in $tablesList;
do
#  echo "dumping $table"_"$partition"
  pg_dump -U postgres -d clickcast -t "$table"_"$partition" |pbzip2 -p2 > $tmpDir/clickcast."$table"_"$partition".sql.bz2 || { echo "exit because pg_dump/pbzip2 failed"; exit 1; };
done

aws s3 cp $tmpDir/ s3://clickcast-backup-wal/archive/partitions-archive/ --include "*.sql.bz2" --recursive
rm $tmpDir/*.sql.bz2
