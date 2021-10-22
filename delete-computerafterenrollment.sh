#!/bin/bash
# 
# 

apiUser="jamfAPIuser"
apiPass='jamfAPIpassword'
prodURL="https://jss.yourdomain.com"
legacyURL="https://jss.yourdomain.com"

prodCount=$(curl -X GET -s -k -u "$apiUser:$apiPass" $prodURL/JSSResource/computergroups/id/184 | xpath "/computer_group/computers/size/text()" 2> /dev/null )
echo "Production Server currently has $prodCount Macs"

legacyCount=$(curl -X GET -s -k -u "$apiUser:$apiPass" $legacyURL/JSSResource/computergroups/id/1 | xpath "/computer_group/computers/size/text()" 2> /dev/null )
echo "Legacy server currently has $legacyCount Macs"

echo "…downloading list of all computers enrolled with new production server…"
ids+=($(curl -X GET -s -k -u "$apiUser:$apiPass" "$prodURL/JSSResource/computers" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))

for id in "${ids[@]}"; do
    serial=$(curl -X GET -s -k -u "$apiUser:$apiPass" "$prodURL/JSSResource/computers/id/$id" | xmllint --xpath xmllint --xpath '/computer/general/serial_number/text()' - )
    if [[ -n "$serial" ]]; then
        echo "Found Mac with serial: $serial, attempting to delete from legacy server…"
        result=$(curl -X DELETE -s -k -f -u "$apiUser:$apiPass" "$legacyURL/JSSResource/computers/serialnumber/$serial" | sed 's/<?xml version="1.0" encoding="UTF-8"?><computer><id>\|//' | sed 's/<\/id><\/computer>\|//')
    else
        echo "Can't get serial for ID $id, waiting…"
        sleep 1
    fi
done

echo "…completed all deletions…"

updatedLegacyCount=$(curl -X GET -s -k -u "$apiUser:$apiPass" $legacyURL/JSSResource/computergroups/id/1 | xpath "/computer_group/computers/size/text()" 2> /dev/null )
echo "Legacy server now has $updatedLegacyCount Macs"

exit 0
