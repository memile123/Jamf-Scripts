#!/bin/bash

# This program will uninstall Microsoft Office 2016

#################
### Variables ###
#################

# Items at the system level to be removed
systemItems=(
	/Applications/Microsoft\ Excel.app
	/Applications/Microsoft\ OneNote.app
	/Applications/Microsoft\ Outlook.app
	/Applications/Microsoft\ PowerPoint.app
	/Applications/Microsoft\ Word.app
	/Applications/Microsoft\ Lync.app
  /Library/Application\ Support/Microsoft/MAU2.0
  /Library/Fonts/Microsoft
  /Library/LaunchDaemons/com.microsoft.office.licensing.helper.plist
  /Library/LaunchDaemons/com.microsoft.office.licensingV2.helper.plist
  /Library/Preferences/com.microsoft.Excel.plist
  /Library/Preferences/com.microsoft.office.plist
  /Library/Preferences/com.microsoft.office.setupassistant.plist
  /Library/Preferences/com.microsoft.outlook.databasedaemon.plist
  /Library/Preferences/com.microsoft.outlook.office_reminders.plist
  /Library/Preferences/com.microsoft.Outlook.plist
  /Library/Preferences/com.microsoft.PowerPoint.plist
  /Library/Preferences/com.microsoft.Word.plist
  /Library/Preferences/com.microsoft.office.licensingV2.plist
  /Library/Preferences/com.microsoft.autoupdate2.plist
  /Library/Preferences/ByHost/com.microsoft
  /Library/Receipts/Office2016_*
  /Library/PrivilegedHelperTools/com.microsoft.office.licensing.helper
  /Library/PrivilegedHelperTools/com.microsoft.office.licensingV2.helper
	/Library/Application\ Support/JAMF/Receipts/Office* #replace with the receipt for your Office installer via Jamf
	/Library/Application\ Support/JAMF/Receipts/Microsoft* #replace with your receipt for your Office/serializer via Jamf
	/Library/Internet\ Plug-Ins/MeetingJoinPlugin.plugin
)

# Items at the user level to be removed
userItems=(
  Library/Containers/com.microsoft.errorreporting
  Library/Containers/com.microsoft.Excel
  Library/Containers/com.microsoft.netlib.shipassertprocess
  Library/Containers/com.microsoft.Office365ServiceV2
  Library/Containers/com.microsoft.Outlook
  Library/Containers/com.microsoft.Powerpoint
  Library/Containers/com.microsoft.RMS-XPCService
  Library/Containers/com.microsoft.Word
  Library/Containers/com.microsoft.onenote.mac
  Library/Group\ ContainersUBF8T346G9.ms/
  Library/Group\ ContainersUBF8T346G9.Office/
  Library/Group\ ContainersUBF8T346G9.OfficeOsfWebHost/
	Library/Application\ Scripts/com.microsoft.Office365ServiceV2
	Library/Preferences/com.microsoft.Lync.plist
	Library/Preferences/ByHost/MicrosoftLyncRegistrationDB.*.plist
	Library/Logs/Microsoft-Lync*.log*
	Documents/Microsoft\ User\ Data/Microsoft\ Lync\ Data/
	Documents/Microsoft\ User\ Data/Microsoft\ Lync\ History/
	Library/Keychains/OC_*
)

#################
### Functions ###
#################

function deleteItems()
{
	declare -a toDelete=("${!1}")

	for item in "${toDelete[@]}"
		do
			if [[ ! -z "${2}" ]]
				then
					item=("${2}""${item}")
			fi

			echo "Looking for $item"

			if [ -e "${item}" ]
				then
					echo "MS Office Uninstall: Removing $item"
					rm -rf "${item}"
			fi
		done
}

####################
### Main Program ###
####################

# Kill the apps, if they are running
echo "MS Office Uninstall: Closing Office-related apps."
killall "Microsoft Excel"
killall "Microsoft Word"
killall "Microsoft PowerPoint"
killall "Microsoft Outlook"
killall "Microsoft OneNote"
killall "Microsoft Auto-Update"
killall "Microsoft Lync"
killall "Microsoft Update Assistant"

# Delete system level items
deleteItems systemItems[@]

# Delete user level items
for dirs in /Users/*/
		do
			deleteItems userItems[@] "${dirs}"
		done

# Delete package receipts
echo "MS Office Uninstall: Removing package receipts."
pkgutil --forget com.microsoft.package.Fonts
pkgutil --forget com.microsoft.package.Microsoft_AutoUpdate.app
pkgutil --forget com.microsoft.package.Microsoft_Excel.app
pkgutil --forget com.microsoft.package.Microsoft_OneNote.app
pkgutil --forget com.microsoft.package.Microsoft_Outlook.app
pkgutil --forget com.microsoft.package.Microsoft_PowerPoint.app
pkgutil --forget com.microsoft.package.Microsoft_Word.app
pkgutil --forget com.microsoft.package.Microsoft_Lync.app
pkgutil --forget com.microsoft.package.Proofing_Tools
pkgutil --forget com.microsoft.package.licensing

exit 0
