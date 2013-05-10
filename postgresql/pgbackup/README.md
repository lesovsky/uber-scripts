### Creating postgresql basebackup and backup validating scripts.
------

**clonepg.sh:**
- perform basebackup and old copies automatic remove (adjust age in script);
- WAL-archive auto-remove need manual adjustment (change WAL-archives path inside script);
- start validation if required (use basebackup-validation.sh).

**basebackup-validation.sh:**
- perform basebackup validation;
- send email notify.

**Notes:**
- Use at your own risk.
- Can be used separately. 
- Explore this scripts before using.
- Need recovery.conf manual change in basebackup-validation.sh.
- Nail uses for email notifications. Change email cmd in basebackup-validation.sh if use other mail program.

**Usage:**

    su - postgres
    mkdir ~postgres/bin
    mv clonepg.sh ~postgres/bin
    mv basebackup-validation.sh ~postgres/bin

now separate basebackup and separate validation

    clonepg.sh --backupdir=/opt/pgbackup 
    basebackup-validation.sh --target=/opt/pgbackup/db-05-09-2013 --sandbox=/opt/pgbackup/sandbox --mailto=lesovsky@gmail.com,allday@e1.ru

or single basebackup and validation

    clonepg.sh --backupdir=/opt/pgbackup --validate=/opt/pgbackup/sandbox --mailto=lesovsky@gmail.com,allday@e1.ru
