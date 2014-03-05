#!/usr/bin/env bash
# Description:  Print all cron task
# Comment:      To start with sudo use "sudo -iE /full/path/script_name"
for c in /etc/crontab /etc/cron.*/* $(find /var/spool/cron -type f)
  do 
    red='\e[0;31m'; NC='\e[0m'
    if [[ $(head -n1 $c) == *#!* ]]
      then
        echo -e "${red}  $c${NC}: found she-bang, probably is a script."
      else
        echo -e "${red}  $c"${NC}
        grep --color=never -E "^[0-9*]+" $c
    fi
    echo
  done
