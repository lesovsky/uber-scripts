#!/bin/bash
CONF='/etc/ldap.conf'
BINDDN=$(grep -m1 "^binddn" $CONF |awk '{print $2}')
BINDPW=$(grep -m1 "^bindpw" $CONF |awk '{print $2}')
BASE=$(grep -m1 "^base" $CONF |awk '{print $2}')
FILTER=$(grep -m1 "^pam_filter" $CONF |awk '{print $2}')
USER=$1

ldapsearch -x -LLL -D $BINDDN -w $BINDPW -b "$BASE" "(&(${FILTER})(uid=${USER}))" sshPublicKey \
|sed -n '/ssh-rsa/,/ssh-rsa/p' |sed -e 's/^sshPublicKey: //' |sed -e 's/^ //g' |sed -e ':a;N;$!ba;s/\n//g'
