#!/usr/bin/env bash
# Description:	Deploy uber-scripts

SRC_URI='https://github.com/lesovsky/uber-scripts/archive/master.tar.gz'

[[ -d ~/bin ]] || mkdir $B
[[ -d ~/tmp ]] || mkdir $W
wget -q --no-check-certificate --tries=3 $SRC_URI -O ~/tmp/us.tgz || exit 1
tar xzf ~/tmp/us.tgz -C ~/tmp/ || exit 1

cp ~/tmp/uber-scripts-master/misc/${0##*/} ~/bin
cp ~/tmp/uber-scripts-master/postgresql/server-checklist.sh ~/bin/
cp ~/tmp/uber-scripts-master/linux/*.sh ~/bin/

cp ~/tmp/uber-scripts-master/linux/bashrc ~/.bashrc
cp ~/tmp/uber-scripts-master/postgresql/psqlrc ~/.psqlrc

(crontab -l |grep -v ${0##*/}; echo "*/10 * * * * ~/bin/${0##*/} &>/dev/null") |uniq - |crontab -

rm -rf ~/tmp/*
