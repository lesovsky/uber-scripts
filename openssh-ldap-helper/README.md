- openssh-ldap-helper/openssh-ldap-helper.sh - perform ssh pubkey validation through LDAP 

first draft, very experimental.

support for non-anonymous access to ldap

/etc/ldap.conf example:

<pre><code>
binddn cn=role,ou=allowed,ou=make,ou=requests,ou=to,dc=ldap
bindpw your_password_here
base ou=where,ou=performs,ou=search,ou=in,dc=ldap
pam_filter objectClass=posixAccount
</code></pre>

todo
- debugging
- non-password access support
- include help
- verbose documentation
