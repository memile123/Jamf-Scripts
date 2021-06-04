#!/bin/bash

currentUser=$(who | awk '/console/{print $1}')
echo $currentUser

osascript -e 'set T to text returned of (display dialog "Please enter a one line business justification for the admin-level action(s) to be taken." buttons {"Cancel", "OK"} default button "OK" default answer "")'
	
    
osascript -e 'display dialog "Your local computer user account has been elevated to admin privileges for 30 minutes.  Activity is logged." buttons {"Cancel", "OK"} default button 2'
   
sudo defaults write /Library/LaunchDaemons/removeAdmin.plist Label -string "removeAdmin"

sudo defaults write /Library/LaunchDaemons/removeAdmin.plist ProgramArguments -array -string /bin/sh -string "/Library/Application Support/JAMF/removeAdminRights.sh"

sudo defaults write /Library/LaunchDaemons/removeAdmin.plist StartInterval -integer 1800

sudo defaults write /Library/LaunchDaemons/removeAdmin.plist RunAtLoad -boolean yes

sudo chown root:wheel /Library/LaunchDaemons/removeAdmin.plist
sudo chmod 644 /Library/LaunchDaemons/removeAdmin.plist

launchctl load /Library/LaunchDaemons/removeAdmin.plist
sleep 10

if [ ! -d /private/var/userToRemove ]; then
	mkdir /private/var/userToRemove
	echo $currentUser >> /private/var/userToRemove/user
	else
		echo $currentUser >> /private/var/userToRemove/user
fi

/usr/sbin/dseditgroup -o edit -a $currentUser -t user admin

cat << 'EOF' > /Library/Application\ Support/JAMF/removeAdminRights.sh
if [[ -f /private/var/userToRemove/user ]]; then
	userToRemove=$(cat /private/var/userToRemove/user)
	echo "Removing $userToRemove admin privileges"
	/usr/sbin/dseditgroup -o edit -d $userToRemove -t user admin
	rm -f /private/var/userToRemove/user
	launchctl unload /Library/LaunchDaemons/removeAdmin.plist
	rm /Library/LaunchDaemons/removeAdmin.plist
	log collect --last 30m --output /private/var/userToRemove/$userToRemove.logarchive
fi

EOF
exit 0
