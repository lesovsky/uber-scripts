#!/usr/bin/env bash
# show postgres processlist, lock and allow cancel or terminate process backends.

print_usage() {
echo 'pgroc.sh show postgres processlist, lock and allow cancel or terminate process backends.'
echo 'work only with PostgreSQL 9.2'
echo 'usage:'
echo '      pg_proc.sh show                  - show processlist'
echo '      pg_proc.sh locks                 - show locks'
echo '      pg_proc.sh cancel pid1 pid2 ...  - cancel backend query'
echo '      pg_proc.sh kill pid1 pid2 ...    - terminate backend'
exit
}

PSQL_CMD='psql -U postgres postgres'

[ -n "$1" ] || print_usage

MODE="$1"
shift

case "$MODE" in

'show' )
	# SHOW PROCESSLIST
	uptime
	echo '-----------------------------------------------------------------------------------------------'
	echo 'select pid,usename,datname,client_addr,query_start,waiting,state,query from pg_stat_activity;' | $PSQL_CMD
;;

'cancel' )
	# CANCEL QUERIES
	[ -n "$1" ] || print_usage
	echo "proclist is $*"
	for PROC in $*; do
		echo "cancel procpid $PROC"
		echo "select pg_cancel_backend($PROC)" | $PSQL_CMD
	done
;;

'kill' )
	# TERMINATE QUERIES
	echo "proclist is $*"
	for PROC in $*; do
		echo "terminate procpid $PROC"
		echo "select pg_terminate_backend($PROC)" | $PSQL_CMD
	done
;;

'locks' )
	# SHOW LOCKS
	q="select \
	     pg_stat_activity.datname,substr(pg_class.relname,1,40), pg_locks.mode,pg_locks.granted, \
	     substr(pg_stat_activity.query,1,30), pg_stat_activity.query_start, \
	     age(now(),pg_stat_activity.query_start) as \"age\", pg_stat_activity.pid \
	   from pg_stat_activity,pg_locks left outer \
	     join pg_class on (pg_locks.relation = pg_class.oid) \
	   where pg_locks.pid=pg_stat_activity.pid order by query_start;"
	echo $q | $PSQL_CMD
;;

* ) print_usage;;
esac
