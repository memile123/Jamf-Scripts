#!/bin/bash

jamfUser="" # API Username
jamfPass="" # API Pass
jamfProURL="" # JAMF instance URL
jssID= # Macbook JAMF ID
lockCode= # JAMF Lock Code 6 Digits
lockMessage="" # Message to display when Macbook is locked
apiData="<computer_command><general><command>DeviceLock</command><passcode>$lockCode</passcode><lock_message>$lockMessage</lock_message></general><computers><computer><id>$jssID</id></computer></computers></computer_command>" #curl data 


# created base64-encoded credentials
encodedCredentials=$( printf "$jamfUser:$jamfPass" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "$jamfProURL/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

# make curl api call
/usr/bin/curl "$jamfProURL/JSSResource/computercommands/command/DeviceLock" \
--silent \
--request POST \
--header "Authorization: Bearer $token" \
--header "Content-Type: application/xml" \
--data "$apiData"

# expire the auth token
/usr/bin/curl "$jamfProURL/uapi/auth/invalidateToken" \
--silent \
--request POST \
--header "Authorization: Bearer $token"
