#!/bin/zsh
##  
##  

#####################################################
#                    Arguments                      #
#####################################################
# Self Service policy ID for installing the available updates
policyToExecute="$4"
# Self Service action {view or execute}
policyAction="$5"
# Allowed number of deferrals
allowedDeferrals="$6"
# The timeout before prompts disappear
promptTimeout="$7"
# Software Update check/download override
forceSoftwareUpdateCheck="$8"
# Deferral override (for VIPs)
forceDisableDeferral="$9"

#####################################################
#                    Settings                       #
#####################################################
# Log File
logFile="/var/log/jamf.log"
function sendToLog () {
	echo "$(date "+%a %b %d %I:%M:%S") $HOST script[$$]: $1" | tee -a "$logFile"
}

#----------------------------------------------------
# Get Software Update icon
#----------------------------------------------------
productVersion=$(sw_vers -productVersion)
sendToLog "macOS Version: $productVersion"

# Big Sur
if [ ! -e "$software_update_icon" ]; then
	software_update_icon="/System/Library/UserNotifications/Bundles/com.apple.SoftwareUpdateNotification.bundle/Contents/Resources/SoftwareUpdate.icns"
fi

# Catalina & Mojave
if [ ! -e "$software_update_icon" ]; then
	software_update_icon="/System/Library/CoreServices/Software Update.app/Contents/Resources/SoftwareUpdate.icns"
fi

# Safety
if [ ! -e "$software_update_icon" ]; then
	software_update_icon="/System/Library/CoreServices/Install Command Line Developer Tools.app/Contents/Resources/SoftwareUpdate.icns"
fi

#----------------------------------------------------
# Get Remaining Deferrals
#----------------------------------------------------
configFile="/usr/local/org/etc/org.softwareupdate.plist"
if [[ ! -f "$configFile" ]]; then
    mkdir -p $(dirname "$configFile")
    defaults write $configFile remainingDeferrals -int $allowedDeferrals
fi
remainingDeferrals=$(defaults read $configFile remainingDeferrals)
if [[ -z $remainingDeferrals ]] || [[ $allowedDeferrals < "0" ]]; then
    remainingDeferrals=$allowedDeferrals
fi

#----------------------------------------------------
# Jamf Helper Config
#----------------------------------------------------
# Jamf Helper - for dialogue boxes
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# Determine currently logged in user
current_user="$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')"
deadlineblock=""
if [[ $remainingDeferrals > 0 && $forceDisableDeferral != "true" ]]; then  
    # Update deadline block
    deadlineblock="

Daily Deferrals Remaining: $(( $remainingDeferrals - 1 ))"
fi
# Available Update Message
available_update_msg="New macOS updates are available. Would you like to install them now?

You may install macOS software updates at any time by navigating to:

 > System Preferences > Software Update $deadlineblock"
# Required Update Message
required_update_msg="Mandatory macOS updates are available and will be installed shortly.

To install these updates immediately, click below. Otherwise, your computer will continue with the update process once the timeout has completed."
# Window title
title="Software Update"

#####################################################
#                   Main Logic                      #
#####################################################
# Begin log file
sendToLog "Software Update Script Started"

if [[ $forceSoftwareUpdateCheck == "true" ]]; then
    # Check if there are any pending OS updates. If not quit to run another day.
    updates=`softwareupdate -l`
    updatesPending=`echo $updates | grep -i recommended`
    [[ -z $updatesPending ]] && updatesPending="none"
    sendToLog="Updates equaled 
        $updates
    "
    if [[ $updatesPending == "none" ]]; then
        sendToLog "No updates pending. Setting plist remainingDeferrals to $allowedDeferrals.  It was $remainingDeferrals.  Exiting"
        defaults write $configFile remainingDeferrals -int $allowedDeferrals
        jamf recon
        exit 0
    else
        sendToLog "Updates found. Continuing..."
        # Download all updates before trying to install them to make a smoother user experiance.
        softwareupdate --download --force --all --no-scan && sendToLog "Updates downloaded."
    fi
fi

sendToLog "Icon path: $software_update_icon"
sendToLog "Allowed Deferrals: $allowedDeferrals"
sendToLog "Remaining Deferrals: $remainingDeferrals"

#----------------------------------------------------
# Deferrals Selection
#----------------------------------------------------
# User not logged in, force install available updates
if [[ "$current_user" == "" && $remainingDeferrals == 0 ]]; then
    sendToLog "No user logged in; executing..."
    jamf policy -id $policyToExecute &
    defaults write $configFile remainingDeferrals -int $allowedDeferrals
    exit 0
fi
# User logged in, tell user about updates
if [[ "$current_user" != "" ]]; then
    echo "User logged in; notifying..."
    if [[ $remainingDeferrals == 0 ]]; then
        # No deferrals left
        sendToLog "No deferrals left"
        # If someone is logged in, prompt them to install updates that require a restart.
        helper_code=$("$jamfHelper" -windowType utility -windowPosition lr -title "$title" -description "$required_update_msg" -icon "$software_update_icon" -button1 "Install Now" -timeout "$promptTimeout" -countdown -countdownPrompt "Time Remaining: " -lockHUD)
        sendToLog "Jamf Helper Exit Code: $helper_code"
        # If they click "Update" then take them to the software update preference pane
        if [[ "$helper_code" == 0 ]]; then
            sendToLog "User approved install or timeout completed; executing..."
            # Update through the GUI
            if [[ $policyAction == "view" ]]; then
                open "jamfselfservice://content?entity=policy&id=$policyToExecute&action=$policyAction"
            else
                jamf policy -id $policyToExecute &
                open x-apple.systempreferences:com.apple.preferences.softwareupdate
                defaults write $configFile remainingDeferrals -int $allowedDeferrals
            fi
            sendToLog "Self Service GUI launched. Exiting script."
            exit 0
        fi
    elif [[ $remainingDeferrals > 0 ]] || [[ $allowedDeferrals < "0" ]]; then
        # If someone is logged in, prompt them to install updates that require a restart.
        helper_code=$("$jamfHelper" -windowType utility -windowPosition ur -title "$title" -description "$available_update_msg" -icon "$software_update_icon" -button1 "No" -button2 "Yes" -cancelButton 1 -defaultButton 1 -timeout "$promptTimeout" -lockHUD)
        sendToLog "Jamf Helper Exit Code: $helper_code"
        # If they click "Update" then take them to the software update preference pane
        if [[ "$helper_code" == 2 ]]; then
            sendToLog "User approved install; executing..."
            # Update through the GUI
            if [[ $policyAction == "view" ]]; then
                open "jamfselfservice://content?entity=policy&id=$policyToExecute&action=$policyAction"
            else
                jamf policy -id $policyToExecute &
                open x-apple.systempreferences:com.apple.preferences.softwareupdate
                defaults write $configFile remainingDeferrals -int $allowedDeferrals
            fi
            sendToLog "Self Service GUI launched. Exiting script."
            exit 0
        else
            sendToLog "User did not approve install; updating remaining deferrals..."
            remainingDeferrals=$(( $remainingDeferrals - 1 ))
            defaults write $configFile remainingDeferrals -int $remainingDeferrals
            exit 0
        fi
    fi
fi
