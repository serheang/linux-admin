#!/usr/bin/env python
""" wc02.py
uses better structure for scripts
"""
import sys
if __name__ == '__main__':
    #data = sys.stdin.read()
    data = open(sys.argv[1]).read()
    chars = len(data)
    words = len(data.split())
    lines = len(data.split('\n'))
    print ("{0} {1} {2}".format(lines, words,chars))
