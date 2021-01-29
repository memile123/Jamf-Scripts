#!/bin/bash
### Sets Standard Dock ###


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                   V A R I A B L E S                                       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dock_util=/usr/local/bin/dockutil
fullOSVersion=$(/usr/bin/sw_vers -productVersion)
majorOSVersion=$(/usr/bin/sw_vers -productVersion | awk -F. {'print $2'})
minorOSVersion=$(/usr/bin/sw_vers -productVersion | awk -F. {'print $3'})

### Checking for logged in user, assigning to the variable loggedInUser.
if [ "$3" != "" ] && [ "$loggedInUser" == "" ]; then
    loggedInUser=$3
else
    loggedInUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')
fi
echo "Creating $loggedInUser's dock."

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                 A P P L I C A T I O N                                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


### Setting Persistent Dock Items ###
sudo -u $loggedInUser $dock_util --remove all --no-restart '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Self Service.app' --no-restart '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Google Chrome.app' --no-restart  '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Safari.app' --no-restart  '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Microsoft Outlook.app' --no-restart '/Users/'"$loggedInUser" 
sudo -u $loggedInUser $dock_util --add '/Applications/Microsoft Word.app' --no-restart '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Microsoft Excel.app' --no-restart '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Microsoft PowerPoint.app' --no-restart '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Microsoft OneNote.app' --no-restart  '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Skype for Business.app' --no-restart  '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app' --no-restart '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Users/'"$loggedInUser"'/Downloads' '/Users/'"$loggedInUser"
sudo -u $loggedInUser $dock_util --add '/Users/'"$loggedInUser"'/Documents' '/Users/'"$loggedInUser"

sudo -u $loggedInUser defaults write com.apple.dock show-recents -bool FALSE


killall -KILL Dock

### Exiting gracefully ###
exit 0
