#!/bin/bash

DOCKUTIL=/usr/local/bin/dockutil

# remove default apps
$DOCKUTIL --remove all --no-restart

# add items to dock
$DOCKUTIL --add	'/Applications/Launchpad.app' --position 1 --no-restart
$DOCKUTIL --add '/Applications/System Preferences.app' --position 2 --no-restart
$DOCKUTIL --add '/Applications/Google Chrome.app' --position 3 --no-restart
$DOCKUTIL --add '/Applications/Microsoft Excel.app' --no-restart --allhomes
$DOCKUTIL --add '/Applications/Microsoft Word.app' --no-restart --allhomes
$DOCKUTIL --add '/Applications/Microsoft Powerpoint.app' --no-restart --allhomes
$DOCKUTIL --add '/Applications/Microsoft Outlook.app' --no-restart --allhomes
$DOCKUTIL --add '/Applications/Microsoft Teams.app' --no-restart --allhomes
$DOCKUTIL --add '/Applications/OneDrive.app' --no-restart --allhomes
$DOCKUTIL --add "~/Downloads" --view list --display folder --sort name --no-restart --allhomes

#delete the job
rm /Library/LaunchDaemons/com.dockutil.default.plist
# unload the daemon
launchctl remove -w /Library/LaunchDaemons/com.dockutil.default.plist
