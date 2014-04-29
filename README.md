### Scripts for Linux system administrators.

--
#### Index:

- checklists/server-checklist.sh - base checklist, draft version.
- linux/getswap.sh - get current swap usage for all running processes.
- linux/showcrons.sh - show cron tasks found in the system (system-wide and per-user cron tasks).
- linux/bashrc - my version of bashrc
- postgresql/pgproc.sh - show postgres processlist, lock and allow cancel or terminate process backends (will be removed in the future).
- postgresql/pgbackup/clonepg.sh - create basebackup of postgresql server cluster and perform validation if required.
- postgresql/pgbackup/basebackup-validation.sh -  perform basebackup validation.
- postgresql/psqlrc - my psqlrc version
- openssh-ldap-helper/openssh-ldap-helper.sh - perform ssh pubkey validation through LDAP (first draft, very experimental)
- scrapper/scrapper-linux-client.sh - Linux client for scrapper utility which gather information from server and show it in human or sql format.
- scrapper/scrapper-freebsd-client.sh - FreeBSD client for scrapper utility with the same purposes as in the scrapper-linux-client.sh.
- scrapper/scrapper-schema.sql - SQL schema for PostgreSQL database for storing information which produced by scrapper-*-client.sh utilities.
- scrapper/scrapper-builder.sh - parse scrapper database and build HTML page with information about servers.
- scrapper/scrapper.crontab - crontasks for scrapper.
- service-configs/ - well-turned configuration files for services.
- misc/megafon-ural-service-guide.sh - script which show the Megafon account status information.

--

#### Disclaimer.
The information contained in this repository is for general information purposes only. The information is provided by me and other contributors and while we endeavour to keep the information up to date and correct, we make no representations or warranties of any kind, express or implied, about the completeness, accuracy, reliability, suitability or availability with respect to the website or the information, products, services, or related graphics contained on the website for any purpose. Any reliance you place on such information is therefore strictly at your own risk.

In no event will we be liable for any loss or damage including without limitation, indirect or consequential loss or damage, or any loss or damage whatsoever arising from loss of data or profits arising out of, or in connection with, the use of this repository.

Through this repository you are able to link to other websites or repos which are not under the our control. We have no control over the nature, content and availability of those sites. The inclusion of any links does not necessarily imply a recommendation or endorse the views expressed within them.

Every effort is made to keep the repo up and running smoothly. However, I takes no responsibility for, and will not be liable for, the repository being temporarily unavailable due to technical issues beyond our control.
