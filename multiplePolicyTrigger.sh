#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#By modifying the below triggernames to correspond with a custom trigger, this script will 
#allow you to execute multiple policies. 
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

jamf policy -trigger triggername1
jamf policy -trigger triggername2

exit 0
