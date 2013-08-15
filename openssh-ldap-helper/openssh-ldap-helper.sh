#!/bin/bash
CONF='/etc/ldap.conf'
BINDDN=$(sed -n "s,^binddn \(.*\)$,\1,p" $CONF)
BINDPW=$(sed -n "s,^bindpw \(.*\)$,\1,p" $CONF)
ACCOUNT_BASE=$(sed -n "s,^account_base \(.*\)$,\1,p" $CONF)
GROUP_BASE=$(sed -n "s,^group_base \(.*\)$,\1,p" $CONF)
SERVER_GROUP=$(sed -n "s,^server_group \(.*\)$,\1,p" $CONF)
BASE=$(sed -n "s,^base \(.*\)$,\1,p" $CONF)
ACCOUNT_FILTER=$(sed -n "s,^account_filter \(.*\)$,\1,p" $CONF)
PUBKEY_ATTR=$(sed -n "s,^pubkey_attr \(.*\)$,\1,p" $CONF)
USER=$1

#check empty params, set defaults if empty parameters exists
if [ -z "$BASE" ]; then logger -t openssh-ldap-publickey "base dn for search not specified" ; exit 1; fi
if [ -z "$ACCOUNT_BASE" ]; then ACCOUNT_BASE="$BASE"; fi
if [ -z "$GROUP_BASE" ]; then GROUP_BASE="$BASE"; fi
if [ -z "$PUBKEY_ATTR" ]; then PUBKEY_ATTR=sshPublicKey; fi

# find group membership, skip if SERVER_GROUP is not specified
# search perform through sssd, and perform search uniqueMember attribute, because with uniqueMember we can use nested groups.
# see man 5 sssd.conf for ldap_group_member parameter.
if [ ! -z "$SERVER_GROUP" ]; then
  if ! getent group $SERVER_GROUP |grep -m1 -q -o $USER
    then logger -t openssh-ldap-publickey "$USER is not in $SERVER_GROUP" ; exit 1;
  fi
fi

# find account pubkey attr
ldapsearch -o ldif-wrap=no -LLL -D $BINDDN -w $BINDPW -b "$ACCOUNT_BASE" "(&(${ACCOUNT_FILTER})(uid=${USER}))" $PUBKEY_ATTR \
 | sed -n "s,^$PUBKEY_ATTR: \(.*\)$,\1,p"
