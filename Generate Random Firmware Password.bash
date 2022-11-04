#!/bin/bash

function logresult()	{
    if [ $? = "0" ] ; then
        echo "$1"
    else
        echo "$2"
        exit 1
    fi
}

# verify whether a firmware password is set
echo "Checking for existing firmware password"
checkFirmwarePassword=$( /usr/sbin/firmwarepasswd -check )

# if a firmware password is already set, stop the script and report failure in Jamf Pro
if [ "$checkFirmwarePassword" != "Password Enabled: No" ] | [ -d /private/tmp/.fp ]; then
	echo "A firmware password is already set. Doing nothing."
	exit 0
else
	echo "No firmware password set"
fi


# create obscure directory
fpdirectory="/private/var/.fp"
/bin/mkdir -p "$fpdirectory"
logresult "Creating \"$fpdirectory\" directory" "Failed creating \"$fpdirectory\" directory"

# generate random password
randpassword=$( /usr/bin/openssl rand -hex 6 )
logresult "Generating 8-character firmware passcode: $randpassword" "Failed generating 8-character firmware passcode."

# write random password to temporary file
/usr/bin/touch "$fpdirectory/$randpassword"
logresult "Writing password to file \"$fpdirectory/$randpassword\"" "Failed writing password to file \"$fpdirectory/$randpassword\""

# update Jamf Pro computer record with firmware password and set only if inventory was updated
/usr/local/bin/jamf recon && /usr/local/bin/jamf setOFP -mode command -password "$randpassword"

# set the firmware password only after a successful inventory update to Jamf Pro
if [ $? = "0" ]; then
    echo "Updating Jamf Pro inventory to upload firmware password"
    echo "Setting firmware password"
    exit 0
else
    echo "Failed setting firmware password"
	exit 1
fi
