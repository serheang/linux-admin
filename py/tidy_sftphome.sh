#!/bin/bash
## Just a simple script to compress and delete old files from certain directory

DIRECTORY=$1
SFTP_DOWNLOAD="/home"
CDAY="6"
DDAY="89"

# First to compress all files in $SFTP_PROCESSED
find ${SFTP_PROCESSED} -type f ! -iname "*.gz" ! -path "template/*" -exec gzip {} \;

# Delete files more than $DDAY old
find ${SFTP_PROCESSED} -mtime ${DDAY} -type f -name "*.gz" ! -path "template/*" -exec rm {} \;
find ${SFTP_PROCESSED} -mtime +${DDAY} -type f -name "*.gz" ! -path "template/*" -exec rm {} \;

# Compress file more than CDAY old
find ${SFTP_DOWNLOAD} -mtime +${CDAY} -type f  ! -iname "*.gz" ! -path "template/*" -exec gzip {} \;

# Delete files more than $DDAY old
find ${SFTP_DOWNLOAD} -mtime ${DDAY} -type f -iname "*.gz" ! -path "template/*" -exec rm {} \;
find ${SFTP_DOWNLOAD} -mtime +${DDAY} -type f -iname "*.gz" ! -path "template/*" -exec rm {} \;


