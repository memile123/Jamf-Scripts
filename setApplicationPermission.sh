#!/bin/sh
####################################################################################################
#
# ABOUT
#
#   Sets permissions on the application passed as Parameters 4 & 5. 
#
####################################################################################################
#
# HISTORY
#
#   Version 1.0, 12-Dec-2017, Dan K. Snelson
#
####################################################################################################


# Variables
loggedInUser=$(stat -f%Su /dev/console)
applicationPath="$5"


# If Parameter 5 is blank, exit ...
if [ -z "${applicationPath}" ]; then

    echo "Application Path not specified; exiting."

    exit 1

fi



# Check for a specified owner (Parameter 4)
# Defaults to currently logged-in user
if [ "$4" != "" ] && [ "$owner" == "" ]; then
    owner="${4}"
else
    echo "Parameter 4 is blank; using \"${loggedInUser}\" as the owner."
    owner="${loggedInUser}"
fi



# Check if the specified application is installed ...
testDirectory="/Applications/${applicationPath}"
if [ -d "${testDirectory}" ] ; then

    echo "/Applications/${applicationPath} located; proceeding ..."

    echo "Setting permissions on /Applications/${applicationPath} ..."

    /usr/sbin/chown ${owner} "/Applications/${applicationPath}"

    echo "Set owner of \"/Applications/${applicationPath}\" to ${owner}."

    exit 0

else

    echo "/Applications/${applicationPath} NOT found; nothing to do."

    exit 0

fi

exit 0
