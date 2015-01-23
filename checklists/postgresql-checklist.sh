#!/bin/bash
# Description: Check various PostgreSQL settings and parameters

PGPATH="/usr/pgsql-9.0/bin:/usr/pgsql-9.1/bin:/usr/pgsql-9.2/bin:/usr/pgsql-9.3/bin:/usr/pgsql-9.4/bin"
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PGPATH"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

PGCONNOPTS=$@
[[ -z $PGCONNOPTS ]] && { echo "${0##*/}: psql connection parameters is not specified"; exit 1; }

main() {
echo "${yellow}Checking target: Compilation options${reset}"
if [[ $(which pg_config 2>/dev/null) ]];
  then PG_CONFIG=$(which pg_config) 
       pgConfigureOpts=$($PG_CONFIG |grep -oE "\-\-(disable|enable)-(debug|cassert|spinlocks)" |xargs)
       if [[ ! -z $pgConfigureOpts ]];
         then echo "PostgreSQL compiled suspiciously, found following compile options: $pgConfigureOpts";
         else echo "Suspicious compile options not found";
       fi
  else { echo "Warning: pg_config not found. Skipping."; }
fi
echo "Debug assertions:" $(psql -qAtX $PGCONNOPTS -c "SELECT setting FROM pg_settings WHERE name = 'debug_assertions'")
}

main
