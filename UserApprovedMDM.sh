#!/bin/sh
###############################################################################
# 
# 
#
#
# Purpose:
#
#
# Change Log:
# 
# - Initial Creation
###############################################################################

#-------------------
# Parse standard package arguments
#-------------------
__TARGET_VOL="$1"
__COMPUTER_NAME="$2"
__USERNAME="$3"

#-------------------
# Variables
#-------------------

JAMF_HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
JAMF_BINARY="/usr/local/bin/jamf"

PROFILES_ICON="/System/Library/PreferencePanes/Profiles.prefPane/Contents/Resources/Profiles.icns"

PROFILES_STATUS="$(/usr/bin/profiles status -type enrollment | grep MDM | awk -F: '{print $2}' | xargs)"

OS_MAJOR="$(sw_vers -productVersion | awk -F. '{print $1}')"
OS_MINOR="$(sw_vers -productVersion | awk -F. '{print $2}')"
OS_BUG="$(sw_vers -productVersion | awk -F. '{print $3}')"
OS_VERSION="$OS_MAJOR.$OS_MINOR.$OS_BUG"
OS_FAMILY="$OS_MAJOR.$OS_MINOR"

INTRO_DESCRIPTION="Funtionality of your system will be limited until you approve enrollment to the Mobile Device Management service.

Press continue to approve MDM enrollment."

INSTRUCTION_DESCRIPTION="To approve your MDM enrollment:
1. From the list, select the MDM Profile
2. In the right hand pane, click the Approve button
3. Follow the prompts to approve enrollment

This window will disappear once MDM enrollment has been approved."

#-------------------
# Functions
#-------------------

enableUserApprovedMDM()
{
    echo "INFO: Attempting to get the user to approve MDM..."

    echo "INFO: Checking for a logged in user."
    CURRENT_USER="$(who | grep console | awk '{print $1}')"

    if [ "$CURRENT_USER" == "" ]; then
        echo "ERROR: Nobody is currently logged in."
        exit 5
    fi

    # Prompt the user that we need them to approve the MDM
    "$JAMF_HELPER" -windowType utility \
        -title "User Approved MDM Enrollment" \
        -heading "Functionality of your system is currently limited." \
        -description "$INTRO_DESCRIPTION" \
        -icon "$PROFILES_ICON" \
        -button1 "Continue" \
        -defaultButton 1

    # Launch the Profiles system preference pane
    open /System/Library/PreferencePanes/Profiles.prefPane

    # Prompt the user with instructions
    "$JAMF_HELPER" -windowType utility \
        -windowPosition ur \
        -title "User Approved MDM Enrollment" \
        -description "$INSTRUCTION_DESCRIPTION" \
        -icon "$PROFILES_ICON" &

    JAMF_HELPER_PID="echo $!"

    PROFILES_STATUS="$(/usr/bin/profiles status -type enrollment | grep MDM | awk -F: '{print $2}' | xargs)"

    while [ "$PROFILES_STATUS" != "Yes (User Approved)" ]; do
        echo "INFO: Waiting for user to complete MDM enrollment"
        # Sleep a beat
        sleep 1

        # Update the profiles status
        PROFILES_STATUS="$(/usr/bin/profiles status -type enrollment | grep MDM | awk -F: '{print $2}' | xargs)"

    done

    # Close the instruction window
    kill $JAMF_HELPER_PID

    # Inform the user we're updating inventory
    "$JAMF_HELPER" -windowType utility \
        -title "User Approved MDM Enrollment" \
        -description "Updating inventory. Please wait..." \
        -icon "$PROFILES_ICON" &

    # Get the process ID for the window
    JAMF_HELPER_PID="echo $!"

    # Update the inventory
    "$JAMF_BINARY" recon

    # Close the recon window
    kill $JAMF_HELPER_PID

    # Prompt the user that we need them to approve the MDM
    "$JAMF_HELPER" -windowType utility \
        -title "User Approved MDM Enrollment" \
        -heading "Your computer is now properly enrolled in MDM." \
        -description "You may close System Prferences. Click the done button to complete this process." \
        -icon "$PROFILES_ICON" \
        -button1 "Done" \
        -defaultButton 1 &

}

#------------------------------------------------------------------------------
# Start Script
#------------------------------------------------------------------------------

# Make sure we're running a macOS version that supports this script
if [ $OS_MINOR -le 12 ]; then
    echo "ERROR: This script is not compatible with macOS $OS_MAJOR.$OS_MINOR"
    exit 1
elif [ $OS_MINOR == 13 ] && [ $OS_BUG -lt 4 ]; then
    echo "ERROR: This script requires macOS 10.13.4 or higher."
    exit 2
fi

# Check the results of the profiles command
if [ "$PROFILES_STATUS" == "No" ]; then
    # The MDM profile has either not installed successfully or was removed by the user. Re-enroll.
    echo "INFO: Not currently enrolled in MDM. Attempting enroll."

    # Ask the JSS for a new MDM profile
    "$JAMF_BINARY" mdm

    # Check and make sure it was installed successfully
    if [ "$?" != "0" ]; then
        echo "ERROR: Failed to enroll in MDM."
        exit 3
    fi

    # Call the function to complete user approved MDM enrollment
    enableUserApprovedMDM

elif [ "$PROFILES_STATUS" == "Yes" ]; then
    # We've successfully enrolled in MDM, but the user has not approved.
    echo "WARN: Enrolled in MDM, but not user approved."

    # Call the function to complete user approved MDM enrollment
    enableUserApprovedMDM

elif [ "$PROFILES_STATUS" == "Yes (User Approved)" ]; then
    # MDM is running and is already user approved. We likely just need an inventory update here.
    echo "INFO: Enrolled in MDM and user has approved. Running recon."

    "$JAMF_BINARY" recon
else
    # We got something we didn't expect from the profile command. Fail out.
    echo "ERROR: Received an unexpected response from profiles. Cannot continue."

    # Exit with an error
    exit 10
fi



#-------------------------------------------------
# Detailed comment on a piece of code.
#-------------------------------------------------

#------------------------------------------------------------------------------
# End Script
#------------------------------------------------------------------------------
exit 0
