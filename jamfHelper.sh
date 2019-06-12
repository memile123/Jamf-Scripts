#!/bin/bash

 if [[ $(sw_vers -productVersion) > "10.14.4" ]]; then
    echo "User Machine is already Updated to Version: $(sw_vers -productVersion)"
    exit 0
else

 loggedInUser=$(stat -f%Su /dev/console)

 jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

 windowType="hud"

 description="Critical security update available for your computer.
 To perform the update:
select 'UPDATE' 
Upon prompt, click 'Allow' from the Safari browser window 
Upon prompt, Log-into Self Service with (Username is $loggedInUser) and Password (Office365/Network Password)
 This machine needs to be connected to power before starting and all-time during this upgrade.
 During this upgrade you won't be able to use this machine and takes around 45mins to complete & reboots automatically
 If you are unable to perform this update at the moment, please select 'Cancel.'
 *Please make sure all important documents are saved to OneDrive before selecting 'UPDATE.'*
 Contact the ITHelpdesk via email for any assistance"

 button1="UPDATE"

 button2="Cancel"

 icon="/Library/Application Support/JAMF/"

 icon_size="200"

 customTrigger='Mojave-test'

 title="************** macOS Mojave Upgrade Wizard **************"

 alignDescription="left"

 alignHeading="center"

 defaultButton="1"

 timeout="900"

 # JAMF Helper window as it appears for targeted computers

 userChoice=$("$jamfHelper" -windowType "$windowType" -lockHUD -title "$title" -timeout "$timeout" -defaultButton "$defaultButton" -icon "$icon" -iconSize "$icon_size" -description "$description" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -button1 "$button1" -button2 "$button2")

 #echo $userChoice


 # If user selects "UPDATE"

 if [ "$userChoice" == "0" ]; then

   open -a Safari
   sleep 3

    osascript -e "tell application \"Safari\" to activate"
   osascript -e "tell application \"Safari\" to open location \"jamfselfservice://content?entity=policy&id=&action=execute\""
elif [ "$userChoice" == "2" ]; then

 echo "User Clicked Cancel"

 fi
exit 0

 fi
