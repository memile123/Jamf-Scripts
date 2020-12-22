#!/bin/bash
####################################################################################################
#
# ABOUT THIS PROGRAM
# NAME
#	AppQuit.sh -- Quit any app
#
# SYNOPSIS
# osascript -e 'quit app "App you want to quit"'
#
# DESCRIPTION
#	Use the policy variable to set the name of the app and Quit it.
####################################################################################################
#
# HISTORY
#
#	Version: 1.0
#
#	- 
#	- 
#
####################################################################################################
#
# HARDCODED VALUES ARE SET HERE
#
# What app? 
# Example: app="OmniGraffle"
# Example: app="Photo Booth"
# No need to \ spaces
# Leave blank to set in the script policy
# Example: app="OneDrive for Business"
#
app=""
#
####################################################################################################
# 
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
####################################################################################################
#
# Check Parameter Values variables from the JSS
#
# Parameter 4 = Name of the app.
# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN TO "app"
if [ "$4" != "" ] && [ "$app" == "" ];then
    app=$4
fi
#
osascript <<EOF
quit app "$app"
EOF
exit 0
