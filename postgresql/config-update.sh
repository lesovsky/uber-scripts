#!/bin/bash
# Description:  Read postgres options from a config and transfer them to another one.
# Usage:        update-config.sh source_config destination_config
# Author: Lesovsky A.V.

[[ $# -lt 2 ]] && { echo -e "Usage:\n  $0 source.conf destination.conf"; exit 1; }

srcCfg=$1
destCfg=$2
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

[[ -f $srcCfg ]] || { echo "${red}ERROR:${reset} $srcCfg doesn't exists. Exit."; exit 1; }
[[ -f $destCfg ]] || { echo "${red}ERROR:${reset} $destCfg doesn't exists. Exit."; exit 1; }

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# make a backup of dest config
echo "${green}INFO:${reset} backup $destCfg to $destCfg.backup"
cp $destCfg $destCfg.backup

echo "${green}INFO:${reset} processing $destCfg"
grep -oE "^[a-z_\.]+ = ('.*'|[a-z0-9A-Z._-]+)" $srcCfg |while read guc ravno value;
  do
      if [[ $(grep -c -w $guc $destCfg) -eq 0 ]]; then
          echo "${yellow}WARNING:${reset} $destCfg doesn't contain ${red}$guc${reset} (value: $value)"
      else
        sed -r -i -e "s|#?$guc = ('.*'\|[a-z0-9A-Z._-]+)|$guc = $value|g" $destCfg || echo "${red}ERROR:${reset} sed failed procssing: $guc = $value"
      fi
  done

echo "${green}Done.${reset} Don't forget to fix parameters with version-specific values like:"
grep -oE "^[a-z_\.]+ = ('.*'|[a-z0-9A-Z._-]+)" $srcCfg |while read guc ravno value;
  do
      if [[ $value =~ (8|9|10)\.[0-9]{1} ]]; then
          echo "$guc = $value"
      fi
  done
