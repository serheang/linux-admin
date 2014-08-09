#!/usr/bin/env python
""" This is a motd type program with commandline input
"""

# get user's name from command line
# raw_input is for python 2
# input is for python 3
name = raw_input('Enter your name: ')
size = len(name)

print "Welcome to python,", name
print "The your name is", size, "characters long"
