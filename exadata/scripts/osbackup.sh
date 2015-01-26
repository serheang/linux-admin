#!/bin/bash

# A script to run NFS backup to ZFS as per 
# instruction in Exadata Owner Guide Chapter 7

## Some definition
ROOTTAR=/root/tar
ROOTMNT=/root/mnt
ZFSMount=$1
MOUNTOPT="rw,intr,soft,proto=tcp,nolock"
LVROOT="/dev/VGExaDb/LVDbSys1"
LVU01="/dev/VGExaDb/LVDbOra1"
SNAPROOT="/dev/VGExaDb/root_snap"
SNAPU01="/dev/VGExaDb/u01_snap"
HOST=`hostname -a`
DATE=`date +%d%m%Y`

if [ $# -lt 1 ]; then
   echo "Please provide the NFS mount in the format of:"
   echo "ip_address:/nfs_location/"
   exit 1
fi

cleanup() {
  cd /
  umount $ROOTMNT/u01
  umount $ROOTMNT
  rm -rf /root/mnt
  lvremove -f $SNAPU01
  lvremove -f $SNAPROOT
  umount $ROOTTAR
}

# Create ROOTTAR if not there; if exist; exit 1
if [ -d "$ROOTTAR" ]; then
   echo "$ROOTTAR exist, please check. Exit now!"
   exit 1
else
   mkdir -p $ROOTTAR
fi

# Mount the ZFS export as NFS
mount -t nfs -o "$MOUNTOPT" "$ZFSMount" "$ROOTTAR"
# Sanity check?
#mount |grep $ROOTTAR
STATUS=$?
if [ $STATUS -ne 0 ]; then
   echo "Unable to mount $ZFSMount on $ROOTTAR.  Exit now!"
   exit 2
fi

# Sanity check whether LVDBSys1 and LVDBOra1 exit?
## Do later?
# Create lv snapshot for root from /dev/VGExaDb/LVDbSys1
lvcreate -L1G -s -n root_snap $LVROOT
e2label /dev/VGExaDb/root_snap DBSYS_SNAP

# Create ROOTMNT and mount LVROOT
if [ -d $ROOTMNT ]; then
   echo "$ROOTMNT exist, please check. Exit now!"
   exit 1
else
   mkdir -p $ROOTMNT
fi

# Mount root_snap to $ROOTMNT
mount /dev/VGExaDb/root_snap /root/mnt -t ext3
STATUS=$?
if [ $STATUS -ne 0 ]; then
   echo "Unable to mount root_snap on $ROOTMNT.  Exit now!"
   exit 3
fi

# Create lv snapshot for /u01 from /dev/VGExaDb/LVDbOra1
lvcreate -L5G -s -n u01_snap $LVU01
e2label /dev/VGExaDb/u01_snap DBORA_SNAP

# create /root/mnt/u01 and mount it
mkdir -p /root/mnt/u01
mount /dev/VGExaDb/u01_snap /root/mnt/u01 -t ext3

# now the real backup to NFS
cd /root/mnt
tar -pjcvf /root/tar/$HOST-$DATE.tar.bz2 * /boot --exclude tar/$HOST-$DATE.tar.bz2 > /tmp/backup_tar-${HOST}_${DATE}.stdout 2> /tmp/backup_tar-${HOST}_${DATE}.stderr

# Manaully check  /tmp/backup_tar-$HOST_$DATE.stderr ?
ERROR_COUNT=`cat  /tmp/backup_tar-$HOST_$DATE.stderr |grep -v 'socket ignored' |grep -v 'Removing leading ' |wc -l `
if [ $ERROR_COUNT -ne 0 ]; then
   echo "Some error detected in /tmp/backup_tar-$HOST_$DATE.stderr, please check. Exit now!"
   exit 4
fi

cleanup
rm /tmp/backup_tar-$HOST_$DATE.stderr
rm /tmp/backup_tar-$HOST_$DATE.stdout
exit 0
