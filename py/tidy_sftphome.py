#!/usr/bin/python

import re, sys, commands, getopt, os

## Some variables
SFTP_PROCESSED="/home/sftp/*/processed"
SFTP_DOWNLOAD="/home/sftp/*/download"

CDAY=6
DDAY=89

print "DOWNLOAD : %s " % (SFTP_DOWNLOAD,)
print "PROCESSED : %s " % (SFTP_PROCESSED,)

def usage():
    print "This is just a simple usage:"
    print "-h / --help	-- to display this usage."
    print "-a 		-- to display -a"

def tidy():
    """
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
    """
    print "This is to run find and remove files."
    COMPRESS_PROCESSED='find %s -type f ! -iname "*.gz" ! -path "template/*" -exec gzip {} \;' % (SFTP_PROCESSED,)
    DELETE_PROCESSED='find %s -mtime +%d  -type f -name "*.gz" ! -path "template/*" -exec rm {} \;' % (SFTP_PROCESSED, DDAY)
    COMPRESS_DOWNLOAD='find %s -mtime +%d -type f  ! -iname "*.gz" ! -path "template/*" -exec gzip {} \;' % (SFTP_DOWNLOAD, CDAY)
    DELETE_DOWNLOAD='find %s -mtime +%d -type f -iname "*.gz" ! -path "template/*" -exec rm {} \;'  % (SFTP_DOWNLOAD, DDAY)


    os.system(COMPRESS_PROCESSED)
    os.system(DELETE_PROCESSED)
    os.system(COMPRESS_DOWNLOAD)
    os.system(DELETE_DOWNLOAD)

    print "Done"

if __name__ == "__main__":
    tidy()
