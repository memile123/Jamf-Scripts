#!/bin/bash

APIUSER="apiuser"  ## Change to your API user account with delete computer privileges
APIPASS="apipass"  ## Change to the password of the above API account

JSSURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')

UUID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $4}')

curl -su "${APIUSER}:${APIPASS}" "${JSSURL}/JSSResource/computers/udid/${UUID}" -X DELETE
