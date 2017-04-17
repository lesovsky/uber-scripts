#!/bin/bash

STAT_DIR="/tmp/fishing"

while true; do
    count=$(sudo -u postgres psql -qAtX -c "select count(*) from pg_stat_activity where now()-xact_start> '00:01:00'::interval and query ~* 'INSERT'")
    echo "$(date) -- $count"
    if [ $count -gt 0 ];
        then
            for i in $(sudo -u postgres psql -qAtX -c "select pid from db_activity where query ~*'INSERT'"); do cat /proc/$i/stack > $STAT_DIR/proc-stack.$i.out & done;
            for i in $(sudo -u postgres psql -qAtX -c "select pid from db_activity where query ~*'INSERT'"); do strace -T -tt -s 128 -p $i -o $STAT_DIR/strace.$i.out & done;
            for i in $(pgrep -P $(head -n 1 /var/lib/postgresql/9.5/replica/postmaster.pid) ); do strace -T -tt -s 128 -p $i -o $STAT_DIR/replica-strace.$i.out & done;
            top -b -c -n 2 -d 2 > $STAT_DIR/top.out
            sudo -u postgres psql -c "select now(),* from repl_activity" > $STAT_DIR/repl_activity.out
            sudo -u postgres psql -c "select now(),* from db_activity" > $STAT_DIR/db_activity.out
            break;
    fi
    sleep 60;
done
while true; do
    count=$(sudo -u postgres psql -qAtX -c "select count(*) from pg_stat_activity where now()-xact_start> '00:00:03'::interval and query ~* 'INSERT'")
    if [ $count -eq 0 ];
        then
            killall strace;
            break;
    fi
    sleep 5;
done
