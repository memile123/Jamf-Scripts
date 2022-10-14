#!/bin/bash

####################################################################################################
# ABOUT THIS SCRIPT
#
#
# DESCRIPTION
# 
#	WARNING - DATA LOSS IS POSSIBLE USING THIS SCRIPT
# 	This script will use JAMF APIs to download macOS updates and force a computer reboot to
#	complete the installation of the updates.
#
# VERSION
# 
# 	1.0
#
####################################################################################################
# CHANGE HISTORY
#
# 
#
####################################################################################################


# Server connection information
URL="JAMF Instance URL"
username="$4"
password="$5"

# Determine Serial Number
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')

initializeSoftwareUpdate(){
	# create base64-encoded credentials
	encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
	
	# Generate new auth token
	authToken=$( curl -X POST "${URL}/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic ${encodedCredentials}" )
	
	# parse authToken for token, omit expiration
	token=$(/usr/bin/awk -F \" 'NR==2{print $4}' <<< "$authToken" | /usr/bin/xargs)
	
	echo ${token}
	
	# Determine Jamf Pro device id
	deviceID=$(curl -s -H "Accept: text/xml" -H "Authorization: Bearer ${token}" ${URL}/JSSResource/computers/serialnumber/"$serialNumber" | xmllint --xpath '/computer/general/id/text()' -)
	
	echo ${deviceID}
	
	# Execute software update	
	curl -X POST "${URL}/api/v1/macos-managed-software-updates/send-updates" -H "accept: application/json" -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" -d "{\"deviceIds\":[\"${deviceID}\"],\"maxDeferrals\":0,\"version\":\"12.6\",\"skipVersionVerification\":true,\"applyMajorUpdate\":true,\"updateAction\":\"DOWNLOAD_AND_INSTALL\",\"forceRestart\":true}"

	# Invalidate existing token and generate new token
	curl -X POST "${URL}/api/v1/auth/keep-alive" -H "accept: application/json" -H "Authorization: Bearer ${token}"
}

initializeSoftwareUpdate 
