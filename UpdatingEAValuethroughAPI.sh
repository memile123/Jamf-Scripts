#!/bin/sh

URL="$4"
userName="$5"
password="$6"

serialNumber=$( system_profiler SPHardwareDataType | grep "Serial Number" | awk -F: '{ print $2 }' | xargs  )

#newName=$( /usr/bin/osascript -e 'text returned of (display dialog "Please, enter your admin password." default answer "" with title "Technician Setup" with icon file posix file "/System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns")' )

PUTxml="<computer><extension_attributes><extension_attribute><name>"EA Name"</name><type>String</type><value>"EA Value Here"</value></extension_attribute></extension_attributes></computer>"

/usr/bin/curl -k "$URL/JSSResource/computers/serialnumber/$serialNumber" --user "$userName:$password" -H "Content-Type: text/xml" -X PUT -d "$PUTxml"

exit 0
