#!/bin/bash
# Description:  Read uncommented parameters from postgresql.conf and transfer them to another one.
# Author:       Lesovsky A.V.
# Usage:        config-update.sh source.conf destination.conf

[[ $# -lt 2 ]] && { echo -e "Usage:\n  $0 source.conf destination.conf"; exit 1; }

srcCfg=$1
destCfg=$2
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

[[ -f $srcCfg ]] || { echo "${red}ERROR:${reset} $srcCfg doesn't exist. Exit."; exit 1; }
[[ -f $destCfg ]] || { echo "${red}ERROR:${reset} $destCfg doesn't exist. Exit."; exit 1; }

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# backup the destination.conf
echo "${green}INFO:${reset} backup $destCfg to $destCfg.backup"
cp $destCfg $destCfg.backup

# do processing
echo "${green}INFO:${reset} processing $destCfg"
grep -oE "^[a-z_\.]+[ ]*=[ ]*('.*'|[a-z0-9A-Z._-]+)" $srcCfg |while read line;
  do
      guc=$(echo $line |cut -d= -f1 |tr -d " "); value=$(echo $line |cut -d= -f2 | tr -d " ")
      if [[ $(grep -c -w $guc $destCfg) -eq 0 ]]; then
          echo "${yellow}WARNING:${reset} $destCfg doesn't contain ${red}$guc${reset} (value: $value)"
      else
        sed -r -i -e "s|#?$guc[ ]*=[ ]*('.*'\|[a-z0-9A-Z._-]+)|$guc = $value|g" $destCfg || echo "${red}ERROR:${reset} sed processing failed: $guc = $value"
      fi
  done

# check version-specific values
echo "${green}Done.${reset} Don't forget to fix parameters with version-specific values."
grep -oE "^[a-z_\.]+[ ]*=[ ]*('.*'|[a-z0-9A-Z._-]+)" $srcCfg |while read line;
  do
      guc=$(echo $line |cut -d= -f1 |tr -d " "); value=$(echo $line |cut -d= -f2 | tr -d " ")
      if [[ $value =~ (8|9|10)\.[0-9]{1} ]]; then
          echo "$guc = $value"
      fi
  done
