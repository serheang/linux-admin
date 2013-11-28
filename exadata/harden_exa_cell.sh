#!/bin/bash

echo "chage -M 90 -m 1 -W 7 root"
chage -M 90 -m 1 -W 7 root
echo "DONE chage for root."
for a_user in `ls -1 /home  | fgrep -f - /etc/passwd | awk -F ':' '{print $1}'`;
do
  echo "chage -M 90 -m 1 -W 7 $a_user"
  chage -M 90 -m 1 -W 7 $a_user
## don't expire the password so that we can update the keys?
#  chage -d 0 $a_user #temporary disable this as it expired password
   echo "Skipped chage -d 0 $a_user"
   echo "DONE chage for $a_user."
done

# Password quality
echo "sed -i 's/5,5,5,5,5/disabled,disabled,16,12,8/g;' /etc/pam.d/system-auth"
sed -i 's/5,5,5,5,5/disabled,disabled,16,12,8/g;' /etc/pam.d/system-auth
echo "DONE sed /etc/pam.d/system-auth"

# Remove all root .ssh/authorized_keys
#rm -rf /root/.ssh ## original steps from harden_passwords_reset_root_ssh
echo "Skipped rm -rf /root/.ssh"
echo "Just remove authorized_keys and id_rsa"
rm -rf /root/.ssh/authorized_keys
rm -rf /root/.ssh/id_rsa*
echo "DONE rm /root/.ssh/authorized_keys /root/.ssh/id_rsa"
exit 0
