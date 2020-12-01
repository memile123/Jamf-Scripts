#!/bin/bash

# Displays a dialog to the end user with a ten minute countdown. If the countdown reaches 0:00 or the user clicks the button, the dialog disappears allowing the remainder of the workflow to proceed.

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
-windowType utility \
-lockHUD \
-title "macOS Catalina Upgrade" \
-heading "ALERT: Your upgrade is about to start!" \
-description "Your Mac will automatically upgrade its operating system in five minutes and can no longer be deferred. Close and save your work now.

This process will take about an hour and your computer may restart multiple times. Leave your computer connected to power and do not move or close your laptop.

To begin the upgrade immediately, press the 'Upgrade Now' button." \
-icon "/Applications/Install macOS Catalina.app/Contents/Resources/InstallAssistant.icns" \
-iconSize 256 \
-button1 "Upgrade Now" \
-defaultButton 1 \
-countdown \
-timeout 600 \
-alignCountdown right

exit 0
