#!/usr/bin/python
"""first python script

This is just my first try of writing python script for nagios

"""

__author__ = "Ser Heang, Tan"
__version__ = "$Revision: 1.0 $"
__license__ = "GPL"

import re,sys,commands

#################
#Set variables
command = "df /"
critical = 95.0
warning = 75.0
#################

#build regex
dfPattern = re.compile('[0-9]+')

#get disk utilization
diskUtil = commands.getstatusoutput(command)

#split out the util %
diskUtil = diskUtil[1].split()[11]

#look for a match. If no match exit and return an
#UNKNOWN (3) state to Nagios

matchobj = dfPattern.match(diskUtil)
if (matchobj):
    diskUtil = eval(matchobj.group(0))
else:
    print "STATE UNKNOWN"
    sys.exit(3)

################################
#Uncomment and change
#diskUtil value to test plug-in
#diskUtil = 98.0
################################

#Determine state to pass to Nagios
#UNKNOWN = 3
#CRITICAL = 2
#WARNING = 1
#OK = 0

def checkdisk():
    if diskUtil >= critical:
        print "FREE SPACE CRITICAL: '/' is %.2f%% full" % (float(diskUtil))
        sys.exit(2)
    elif diskUtil >= warning:
        print "FREE SPACE WARNING: '/' is %.2f%% full" % (float(diskUtil))
        sys.exit(1)
    else:
        print "FREE SPACE OK: '/' is %.2f%% full" % (float(diskUtil))
        sys.exit(0)

def main():
    argp = argparse.ArgumentParser(description=__doc__)
    argp.add_argument('-w', '--warning', metavar='RANGE', default='',
                      help='return warning if load is outside RANGE')
    argp.add_argument('-c', '--critical', metavar='RANGE', default='',
                      help='return critical if load is outside RANGE')
    argp.add_argument('-r', '--percpu', action='store_true', default=False)
    argp.add_argument('-v', '--verbose', action='count', default=0,
                      help='increase output verbosity (use up to 3 times)')
    args = argp.parse_args()
    checkdisk(args.warning, args.critical),

if __name__ == '__main__':
    #main()
    checkdisk()
