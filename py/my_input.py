""" This is just a simple python script
to capture input from keyboard
"""
__author__ = "Tan Ser Heang (serheang@gmail.com)"
__version__ = "$Revision: 1.0 $"
__date__ = "$Date: 2014/07/07 $"
__copyright__ = "Copyright and copyleft (c) 2014 Tan Ser Heang"
__license__ = "GPL v2"

print "Halt!"
user_reply=raw_input("Who goes there? ")
print "Welcome,", user_reply
number_input=input("How old are you? ")
print "You are ",number_input,"."


print "user_reply is ", type(user_reply)
print "number_input is ", type(number_input)