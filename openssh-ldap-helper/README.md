**openssh-ldap-helper/openssh-ldap-helper** -   perform ssh pubkey validation through LDAP 

- starting with OpenSSH version 6.2;
- based on ldapsearch utility;
- use default /etc/openldap/ldap.conf for connections;
- may use /etc/ldap.conf configurations used by PAM/NSS LDAP;
- support for nested groups through SSSD (account need store in uniqueMember attribute);
- support for anonymous and non-anonymous access to ldap;
- support for group-based access control (account must be a memeber of specified group);
- ability to specify a search path for accounts and groups (account_base and group_base);
- ability to change the filter to search for accounts (account_filter, default is 'objectClass: posixAccount);
- can change the attribute by which to search for the publickey (pubkey_attr, default is sshPublicKey);
- support for multiple keys stored in LDAP account;
- support for commands and options attached in publickey (no-pty,command="...",no-agent-forwarding, etc).

**Install**
<pre><code>
# git clone https://github.com/lesovsky/uber-scripts/tree/master/openssh-ldap-helper
# mkdir /usr/libexec/openssh
# cp openssh-ldap-helper/openssh-ldap-helper /usr/libexec/openssh/
# chmod 755 /usr/libexec/openssh/openssh-ldap-helper
# chown root: /usr/libexec/openssh/openssh-ldap-helper
# vi /etc/ssh/sshd_config
AuthorizedKeysCommand /usr/libexec/openssh/openssh-ldap-helper
AuthorizedKeysCommandUser root
# vi /etc/ldap.conf
# chown root: /etc/ldap.conf && chmod 600 /etc/ldap.conf 
Restart sshd service now.

Minimal /etc/ldap.conf example:
uri ldap://ldap1.server.org ldap://ldap2.server.org ldap://ldap3.server.org
base ou=where,ou=performs,ou=search,ou=in,dc=ldap

Full /etc/ldap.conf example:
uri ldap://ldap1.server.org ldap://ldap2.server.org ldap://ldap3.server.org
binddn cn=someuser,ou=somegroup,ou=in,dc=ldap
bindpw plaintext_password_here
base dc=ldap
account_base ou=where,ou=performs,ou=accounts,ou=search,ou=in,dc=ldap
group_base ou=where,ou=performs,ou=groups,ou=search,ou=in,dc=ldap
account_filter objectClass=posixAccount
server_group production-servers
pubkey_attr sshPublicKey
</code></pre>

**Troubleshoot**

Errors are written to syslog by logger utility. Check system logs.
Test run:
<pre><code>
# /usr/libexec/openssh/openssh-ldap-helper username
</code></pre>


**todo**
- debugging
- include help
