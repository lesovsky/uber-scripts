- openssh-ldap-helper/openssh-ldap-helper.sh - perform ssh pubkey validation through LDAP 

first draft, very experimental.

support for non-anonymous access to ldap

/etc/ldap.conf example:

```uri ldap://auth1.server.ru ldap://auth2.server.ru ldap://auth3.server.ru\n
port 636\n
binddn cn=role,ou=allowed,ou=make,ou=requests,ou=to,dc=ldap
bindpw your_password_here
base ou=where,ou=performs,ou=search,ou=in,dc=ldap
pam_filter objectClass=posixAccount
timelimit 30
bind_timelimit 30
ssl start_tls
tls_cacert /etc/openldap/cacerts/cacert.pem
pam_password md5```

todo
- debugging
- non-password access support
- include help
- verbose documentation
