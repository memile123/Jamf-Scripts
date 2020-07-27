#!/bin/bash

#################################################
# Display Local Admin Password - Self Service
# July 2020
# 
#################################################

#### NOTES ######################################
############ Script Parameters Info #############
## 4 - API Username String (Required)
## 5 - API Password String (Required)


# Script Variables
jssURL="put your jss url here"
apiUser='put apiuser here'
apiPass='put apipassword here'
currUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}  ')
currUserUID=$(id -u "$currUser")
udid=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')
sn=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Determine if we are getting LAPS for this device or another
lapsDevice=$(
/bin/launchctl asuser "$currUserUID" sudo -iu "$currUser" /usr/bin/osascript <<APPLESCRIPT
set answer to the button returned of (display dialog "Will you be getting LAPS for this device or another?" buttons {"This Mac", "Other Mac"} default button 1)
APPLESCRIPT
)
if [[ "$lapsDevice" == "This Mac" ]]; then
echo "using this macs SN"
sn=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
else
echo "prompting for Serial Number"
sn=$(/bin/launchctl asuser "$currUserUID" sudo -iu "$currUser" /usr/bin/osascript <<APPLESCRIPT
set sn to the text returned of (display dialog "Enter the Serial Number of the device you'd like to retrieve the LAPS for:" default answer "")
APPLESCRIPT
)
fi
# ID of the EA that is storing the password from the LAPS policy
EAID=00
xml=$(curl -s -u $apiUser:$apiPass -H "Accept: application/xml" $jssURL/JSSResource/computers/serialnumber/$sn/subset/extension_attributes | xpath "//*[id=$EAID]/value/text()" 2>&1)
lapsPass=$(echo $xml | awk '{print $7}')

# Checks the lapsPass variable to see if the EA contains the local admin password, if not displays the message stating the password is not stored in the EA then exits
if [[ -z "$lapsPass" ]]; then
lapsPass="Unable to find password in jamf."
lapsError=$(
/bin/launchctl asuser "$currUserUID" sudo -iu "$currUser" /usr/bin/osascript <<APPLESCRIPT
set getPass to do shell script "echo $lapsPass"
set showPass to display dialog " " & getPass & " " with title "Password Not Found" buttons {"Exit"} default button 1 giving up after 5
APPLESCRIPT
)
exit 0
fi

displayPass=$(
/bin/launchctl asuser "$currUserUID" sudo -iu "$currUser" /usr/bin/osascript <<APPLESCRIPT
set getPass to do shell script "echo \"$lapsPass\""
set showPass to display dialog "Password: " & getPass & " " with title "Password" buttons {"Copy"} default button 1 giving up after 30
if button returned of showPass equals "Copy"
set the clipboard to getPass
end if
APPLESCRIPT
)

exit 0
