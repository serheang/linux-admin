#!/bin/bash

## value in days
MAXDAYS=35
MINDAYS=1
WARNING=7


chage -M ${MAXDAYS} -m ${MINDAYS} -W ${WARNING} root
for a_user in `ls -1 /home  | fgrep -f - /etc/passwd | awk -F ':' '{print $1}'`;
do
  chage -M ${MAXDAYS} -m ${MINDAYS} -W ${WARNING} $a_user
  chage -d 0 $a_user #force $a_user to change password immediately
done

# Password quality
sed -i 's/5,5,5,5,5/disabled,disabled,16,12,8/g;' /etc/pam.d/system-auth

# Remove all root .ssh/authorized_keys
rm -rf /root/.ssh/authorized_keys


