#!/bin/bash

# A simple script to check which is master/slave db

PROGNAME=`basename $0`
#PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
PROGPATH=/usr/lib64/nagios/plugins
REVISION="1.0"

. $PROGPATH/utils.sh

## This need to be run as root or grant "crm_mon" sudo to the user

if [ $UID -ne 0 ]; then
    if  `sudo -l |grep crm_mon` ; then
        SUDO="sudo"
    elif  ! `id $USER |grep haclient` ; then
        echo "$USER do not have sudo access to crm_mon."
        echo "Nor in haclient group nor root"
        exit 1
    fi
fi

HOST=`hostname`
CRM_MON="`which crm_mon 2>/dev/null`"
if [ -n "${CRM_MON}" ]; then 
    CRM=`$SUDO $CRM_MON -1`
else
    echo "crm_mon command not found."
    exit 1
fi

PR="240.156"
DR="240.246"

check_master () {
M=`$CRM_MON -1 |grep Masters | awk '{print $(NF-1)}'`
if [ "$M" == "$HOST" ]; then
    AWAL=`ps -ef |grep [w]al |grep [s]ender |grep $PR|awk '{print $NF}'`
    PWAL=`ps -ef |grep [w]al |grep [s]ender |grep $DR|awk '{print $NF}'`
#    echo "Replication status: "
#    echo "	Active Sender: $AWAL"
#    echo "	Passive Sender: $PWAL"
    echo "Master DB. Active Replication: $AWAL, Passive Replication: $PWAL"
fi
}

check_slave() {
S=`$CRM_MON -1 |grep Slaves | awk '{print $(NF-1)}'`
if [ "$S" == "$HOST" ]; then
    RWAL=`ps -ef |grep [w]al |grep [r]eceiver|awk '{print $NF}'`
#    echo "$HOST is Slave DB."
#    echo "Replication status: "
#    echo "	Receiver: $RWAL"
    echo "Slave DB. Active Replication: $RWAL"
fi
}

check_top() {
T=`$CRM_MON -A1 |grep -v 'top-' |grep pgsql-top |awk '{print $NF}'`
if [ "$T" == "$HOST" ]; then
    RWAL=`ps -ef |grep [w]al|grep [r]eceiver |awk '{print $NF}'`
    SWAL=`ps -ef |grep [w]al|grep [s]ender |awk '{print $NF}'`
#    echo "$HOST is Top DB."
#    echo "Replication status: "
#    echo "	Receiver: $RWAL"
#    echo "	Sender:   $SWAL"
    echo "Passive Top DB. Pasive Replication: $RWAL"
fi
}

check_bottom() {
B=`$CRM_MON -A1 |grep -v 'bottom-' |grep pgsql-bottom |awk '{print $NF}'`
if [ "$B" == "$HOST" ]; then
    RWAL=`ps -ef |grep [w]al |grep [r]eceiver|awk '{print $NF}'`
#    echo "$HOST is Bottom DB."
#    echo "Replication status: "
#    echo "	Receiver: $RWAL"
    echo "Passive Bottom DB. Pasive Replication: $RWAL"
fi
}

check_master
check_slave
check_top
check_bottom
exit $STATE_OK
