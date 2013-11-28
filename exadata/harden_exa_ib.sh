#!/bin/bash

echo "To fix Oracle bug 13494021 and 15715700 on `hostname -a`"
echo "Stupid Oracle bugs!"

## Oracle Bug 15715700

chmod 0400 /conf/shadow* /etc/shadow
ls -l /etc/shadow* /conf/shadow*

echo "Done workaround for bug 15715700, which shadow file is world-readable!"

## Oracle Bug 13494021

cd /conf
cp -p shadow shadow.backup
ls /conf/shadow*
cd /etc
cp -p shadow /conf/shadow
ln -sf /etc/shadow.ilom shadow 
ls -l /etc/shadow* /conf/shadow*

echo "Done workaround for bug 13494021!"

echo "How can this stupid bug not detected by Oracle before production?"

exit 0

