#!/bin/bash
# Script to change password for user to ilom system
## Desc: A simple script to change password for user
## Date: 22 Nov 2012
## Version: 1.0
## CHANGES: More checking and checking done
## Author: serheang

# Configuration
trap "cleanup ; exit 2" INT TERM #EXIT
umask 0077
FMBMAILBOX="serheang+git@gmail.com" # replace this with your functional mail
MAILBOX="serheang+git@gmail.com" # replace this with your personal mail for debugging
DATE=`date +%Y-%m-%d`
DOY=`date +%j`
DATETIME=`date +%Y-%m-%d"T"%H:%M:%S`
EXPIREDTIME=`date -d 30days +%Y-%m-%d"T"%H:%M:%S`
ERRORLOG=/tmp/error-$DATE.log
SSH_OPTIONS="-t -t -o UserKnownHostsFile=/dev/null -o ConnectTimeout=90 -o Preferredauthentications=publickey -o Protocol=2 -o BatchMode=yes -o StrictHostKeyChecking=no"
SSH_USER="root" ### Must be root to run chpasswd
OWNER="CS.SH.MY.EXADATA" ## Owner group to be use in XML output
MKPASSWD="$HOME/bin/mkpasswd2"
IPMITOOL='ipmitool sunoem cli "set /SP/users/${USERNAME} password=${PASSWORD}" ${PASSWORD}'
PASSOPT="-l 12 -d 2 -c 2 -C 2 -s 0 -2"
if [[ ${1} == "-m" ]]; then
   CHPASSWD="/usr/sbin/chpasswd -c MD5"
   shift
else
   CHPASSWD="/usr/sbin/chpasswd -c SHA512"
fi

## Usage
usage (){
   echo "Usage: $0 (SUDO)[-c|-x|-X] (-P <PASSWORD>) [-j <hostname>] [ {-s} <hostname> (-u <username>) (s) | {-f} <file> (-u <username>) (s) |  {-h|-help|usage} ]"
   echo "SUDO - to force the command to run as sudo rootsh -i -u root -- * "
   echo "-j <hostname> - server which used as jump point"
   echo "-s <hostname> - to change password for that particular host"
   echo "-f <file> - to change password for the hosts in <file>"
   echo "   example contain of <file> - 
		abc.shell.com
		xyz.shell.com"
   echo "-u <username> - username's password to be updated"
   echo "-c|-x|-X - generate CSV (-c), XML (-x), XLS (-X) file format
                XML format is according to Keepass 1.x format,
                XLS format is according to Password Vault format.
                If not specific, default file format would be CSV."
   echo " s - is an optional function to set 1 password for all hosts"
   echo "-P <PASSWORD> - is an optional options to set password to <PASSWORD> specific"
   exit 0
}

## Sanity check
if [[ ${1} == "SUDO" ]]; then
   SUDO="sudo rootsh -i -u root -- "
   shift
fi
if [[ ${1} == "-c" ]]; then
   echo "Create CSV."
   FILETYPE="csv"
   shift
elif [[ ${1} == "-x" ]]; then
   echo "Create XML."
   FILETYPE="xml"
   shift
elif [[ ${1} == "-X" ]]; then
   echo "Create XLS."
   FILETYPE="xls"
   shift
else
   echo "Default is CSV."
   FILETYPE="csv"
fi

if [ "$1" == "-j" ]; then
   JUMPHOST=${2}
   if [ -z "${JUMPHOST}" ]; then
      echo "JUMPHOST no define!"
      exit 123
   fi
   shift 2
else
   JUMPHOST=""
fi
if [[ ${1} == "-P" ]]; then
   MPASSWORD="$2"
   MANUAL=1
   shift 2
fi


OPTION=${1}
if [[ ${OPTION} == "-s" ]]; then
   HN=${2}
   HSLIST=`basename ${HN} .shell.com`
   if [[ -z "${HN}" ]]; then
      echo "HOST not provided.  Exiting now."
      exit 1
   fi
elif [[ ${OPTION} == "-f" ]]; then
   HOSTLIST=${2}
   HSLIST=`basename ${HOSTLIST} .lst`
   if [[ -z "${HOSTLIST}" ]]; then
      echo "HOSTLIST not provided.  Exiting now."
      exit 1
   fi
   if [[ ! -s ${HOSTLIST} ]]; then
      echo "${HOSTLIST} empty/not found.  Exiting now."
      exit 1
   fi
else
   usage
fi

if [[ ${3} == "-u" ]]; then
   USERNAME=${4}
   shift 2
fi
SINGLE=${3}
if [[ ${SINGLE} == "s" ]]; then
   shift 
fi

if [[ $FILETYPE == "xml" ]]; then
   PASSGRP="${3}" ## This maybe should be a variable
   PASSSUBGRP="${4}" ## Should be variable too
   if [[ -z "$PASSGRP" || -z "$PASSSUBGRP" ]]; then
      echo "PASSWORD GROUP and SUBGROUP missing!"
      exit 123
   fi
fi

echo "PASS GROUP = $PASSGRP; SUBGROIP = $PASSSUBGRP"
echo "Filetype $FILETYPE"
echo "USER $USERNAME"
echo "HOST $HN or HOSTLIST: $HOSTLIST"
echo "Jumphost $JUMPHOST"
echo "CHPASSWD :  $CHPASSWD"

# Function
digit () {
   HOST=$1
      IPADDR=`host $HOST | tail -n1|awk '{print $NF}'`
      if [ "${IPADDR}" == "2(SERVFAIL)" ]; then
         IPADDR=""
      fi

     if [ -n "${IPADDR}" ]; then
      echo "${HOST}   address    $IPADDR" 
     else
      echo `date` "NO IP for $HOST i" 
     fi
}

hostalive () {
   HOST=$1
   if [ -z "$JUMPHOST" ]; then
      ping -c 4 -q $HOST >/dev/null 2>&1
      if [[ $? -ne 0 ]]; then
         echo "$HOST not pingable." |tee -a $ERRORLOG
         return 0
	  fi
   else
      echo "This $HOST is connected via $JUMPHOST. Skipped hostalive check!"
	  return 0	
   fi
}

filedate () {
FILE=$1
if [ -s $FILE ]; then
        DoC=`stat -c=%y $FILE | awk -F"-" '{ printf $3 }' | cut --delimiter=' '  -f1`
        DoM=$((`date +%d` - DoC))
        echo "$FILE last modified $DoM days ago"
        if [ $DoM -gt 20 ]; then
           echo "Remove $FILE as it was last modified $DoM days".
           rm $FILE
        fi
fi
}

logit () {
  if [ -z "$3" ]
  then
    logger -s -p local7.notice -t "$1" "$2"
  else
    logger -s -p local7.$3 -t "$1" "$2"
  fi
}

changepw () {
if [[ $MANUAL -eq 1 ]]; then
   PASSWORD=$MPASSWORD
   echo "PASSWORD is hardcoded to $MPASSWORD."
else
   echo "Generating random password with parameter -l 12 -d 2 -c 2 -C 2 -s 2 -2 "
   PASSWORD="`$MKPASSWD $PASSOPT`" # -s 0 disable special character
   ## Maybe a small loop to do sanity check ?
   PASS=$(perl -e 'print crypt($ARGV[0], "PASSWORD")' ${PASSWORD} ${DATE})
   ## Checking whether the $PASSWORD and $PASS valid
   if [[ -z "$PASSWORD" || -z "$PASS" ]]; then
      echo "password or encrypted password not valid"
      echo "Regenerate new password again"
      changepw
   fi
fi
}

ilom () {
IPMITOOL="ipmitool sunoem cli 'set /SP/users/${USERNAME} password=${PASSWORD}' ${PASSWORD}"
}

ssh_changepw () {
   HOST=$1 
   ACCOUNT=`basename ${HOST} .shell.com`-${USERNAME}-ilom
   if [[ -n "${SINGLE}" ]]; then
      if [[ "${SINGLE}" == "s" ]]; then 
         echo "One password"
      else
         changepw
      fi
   else
      changepw
   fi
#   echo "HOST: $HOST PASS: $PASSWORD";
#  If jumphost defined, then use this
   ilom
   if [ -n "$JUMPHOST" ]; then
      ssh -q -A -l $SSH_USER $JUMPHOST ssh -q $SSH_OPTIONS $HOST "unset HISTFILE; bash -c \"$IPMITOOL\""
EOF
   else
      ssh -q -t -l $SSH_USER $SSH_OPTIONS $HOST "unset HISTFILE;bash -c \"$IPMITOOL\""
   fi
   if [[ $? -eq 0 ]]; then 
      echo "Password for $USERNAME has been changed on $HOST!";
      createbody >> $PASSWDFILE
   else
      echo "Failed to change password for $USERNAME!" 
   fi
}

cleanup () {
   echo "removing $PASSWDFILE and $EPASSWD"
   rm -f $PASSWDFILE 
   rm -f $EPASSWD
   echo "DONE!"
#   trap - INT TERM EXIT
}

xmlhead () {
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
echo "<pwlist>" 
}

xmlbody () {
echo "<pwentry>"
echo "	<group tree=\"${PASSGRP}\\${PASSSUBGRP}\">${USERNAME}</group>"
echo "	<title>${ACCOUNT}</title>"
echo "	<username>${USERNAME}</username>"
echo "	<url>${HOST}</url>"
echo "	<password>${PASSWORD}</password>"
echo "	<notes>${USERNAME} on ${HOST}-ilom updated on ${DATE}</notes>"
echo "	<uuid>`uuidgen -r`</uuid>"
echo "	<image>0</image>"
echo "	<creationtime>${DATETIME}</creationtime>"
echo "	<lastmodtime>${DATETIME}</lastmodtime>"
echo "	<lastaccesstime>${DATETIME}</lastaccesstime>"
echo "	<expiretime expires=\"false\">${EXPIREDTIME}</expiretime>"
echo "</pwentry>"
}

xmltail () {
echo '</pwlist>' 
}

csvhead () {
echo "\"Account\",\"Login Name\",\"Password\",\"Web Site\",\"Comments\"" 

}
csvbody () {
echo "\"${ACCOUNT}\",\"${USERNAME}\",\"${PASSWORD}\",\"${HOST}\",\"${DATE}\"" 
}

xlshead () {
echo "\"owner\",\"username\",\"password\",\"hostname\",\"comment\""
}

xlsbody () {
echo "\"${OWNER}\",\"${USERNAME}\",\"${PASSWORD}\",\"${HOST}-ilom\",\"${DATE}\""
}

createhead () {
      if [[ "${FILETYPE}" == "csv" ]]; then
         csvhead 
      elif [[ "${FILETYPE}" == "xml" ]]; then
         xmlhead 
      elif [[ "${FILETYPE}" == "xls" ]]; then
         xlshead
      fi
}

createbody () {
      if [[ "${FILETYPE}" == "csv" ]]; then
         csvbody 
      elif [[ "${FILETYPE}" == "xml" ]]; then
         xmlbody 
      elif [[ "${FILETYPE}" == "xls" ]]; then
         xlsbody
      fi
}
gpg_encrypt () {
   export GPG_TTY=`tty`
   gpg --import ~/.exadata/.Exadata_pub.asc
   gpg  --yes --no-tty  -q --encrypt -r Exadata --trust-model always  $PASSWDFILE
}
   
# Main

if [[ -z "${USERNAME}" ]]; then
   read -p "Enter username : " USERNAME
   if [[ -z "${USERNAME}" ]]; then
      echo "username not valid" 
      exit 2
   fi
fi
PASSWDFILE=~/.exadata/password-ilom_${USERNAME}_${HSLIST}.${FILETYPE}
EPASSWD=~/.exadata/password-ilom_${USERNAME}_${HSLIST}.${FILETYPE}.gpg
createhead >> $PASSWDFILE

## generate random password with mkpasswd
changepw

if [[ "${OPTION}" == "-f" ]]; then
   for HN in `cat $HOSTLIST |awk '{print $1}'`
   do
      echo $HN
      if [[ $? -ne 0 ]]; then
         echo "Unable to change password for $HN" |tee -a $ERRORLOG
         continue
      else
         ssh_changepw $HN
      fi
   done
elif  [[ "$OPTION" == "-s" ]]; then
      if [[ $? -ne 0 ]]; then
         echo "Unable to change password for $HN" |tee -a $ERRORLOG
         rm $PASSWDFILE
         cleanup
      else
         ssh_changepw $HN
      fi
      HOSTLIST=$HN
fi

if [[ $FILETYPE == "xml" ]]; then
   xmltail >> $PASSWDFILE
fi
if [[ $FILETYPE == "xls" ]]; then
   ssconvert $PASSWDFILE $PASSWDFILE 2>/dev/null
fi


if [[ -s $ERRORLOG ]]; then
   echo "Error when running $0 for $USERNAME $DATE" $MAILBOX < $ERRORLOG
   rm $ERRORLOG
fi
if [[ -s $PASSWDFILE ]]; then
   echo "Not going to encrypt $PASSWDFILE!"
   echo "Unable to send attachment with the default mail command.  Will need to scp manually $PASSWDFILE"
   echo "Run cleanup manually after scp!"
fi
exit 0
