#!/bin/bash
#Mounts the requested share if it doesn't already exist if left blank it will attempt to mount AD SMBhome
#Accepts shares in the form smb://server/share

##### Start seperate process #####
(

##### SUBROUTINES #####

Share_Path_Valid() {
if [[ -z "$Share_Path" ]]; then
Machine_Domain=$(dscl /Active\ Directory/ -read . SubNodes | awk '{print $2}')
Share_Path="$(dscl "/Active Directory/$Machine_Domain/All Domains" -read /Users/$Current_User SMBHome | awk '!/is not valid/' | sed -e 's/SMBHome: /smb:/g' -e 's/\\/\//g')"
fi
if [[ "$Share_Path" ]]; then
logger "Sharemount:$Share_Name Path check PASS $Share_Path"
return 0
else
logger "Sharemount:$Share_Name Path check FAIL"
return 1
fi
}

#####

User_Ready() {
Loop_End=$((SECONDS + 60))
Current_User=$(stat -f%Su /dev/console | awk '!/root/')
while [[ -z "$Current_User" ]] && [[ $SECONDS -lt $Loop_End ]]; do
sleep 10
Current_User=$(stat -f%Su /dev/console | awk '!/root/')
done
if [[ "$Current_User" ]]; then
logger "Sharemount:$Share_Name User check PASS $Current_User"
return 0
else
logger "Sharemount:$Share_Name User check FAIL"
return 1
fi
}

#####

Finder_Ready() {
Loop_End=$((SECONDS + 60))
while [[ -z "$(ps -c -u $Current_User | awk /CoreServicesUIAgent/)" ]] && [[ $SECONDS -lt $Loop_End ]]; do
sleep 10
done
if [[ "$(ps -c -u $Current_User | awk /Finder/)" ]]; then
logger "Sharemount:$Share_Name Finder check PASS"
return 0
else
logger "Sharemount:$Share_Name Finder check FAIL"
return 1
fi
}

#####

Not_Mounted() {
if [[ -z "$(mount | awk '/'$Current_User'/ && /\/'$Share_Name' /')" ]]; then
logger "Sharemount:$Share_Name Mount check PASS $Share_Name"
return 0
else
logger "Sharemount:$Share_Name Mount check FAIL already mounted"
return 1
fi
}

#####

Mount_Drive() {
True_Path=$(echo $Share_Path | sed 's/\/\//\/\/'$Current_User'\@/g')
logger "Sharemount:$Share_Name Attempting to mount $True_Path"
sudo -u $Current_User osascript -e 'mount volume "'$True_Path'"'
}

##### START #####

Share_Path=$4
Share_Name="$(echo $Share_Path | awk -F"/" '{print $NF}')"

if User_Ready && Finder_Ready && Share_Path_Valid && Not_Mounted; then
sleep 4
Mount_Drive
else
logger "Sharemount:$Share_Name Conditions not met to attempt drive mounting $Share_Path"
fi

##### End seperate process #####
) &

##### FIN #####
