#!/bin/bash

# Lets Kill all Google Chrome Processes
killAll 'Google Chrome'

# Desired default browser string
defaultBrowser='com.google.chrome'
#defaultBrowser='com.apple.safari'
#defaultBrowser='org.mozilla.firefox'

# Get Currently-logged in User
consoleUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
/bin/echo "consoleUser is $consoleUser"
# plistBuddy executable
plistBuddy='/usr/libexec/PlistBuddy'

# Plist directory
plistDirectory="/Users/${consoleUser}/Library/Preferences/com.apple.LaunchServices"

# Plist name
plistName="com.apple.launchservices.secure.plist"

# Plist location
plistLocation="$plistDirectory/$plistName"
/bin/echo "plistLocation is $plistLocation"

# Array of preferences to add
prefsToAdd=("{ LSHandlerContentType = \"public.url\"; LSHandlerPreferredVersions = { LSHandlerRoleViewer = \"-\"; }; LSHandlerRoleViewer = \"$defaultBrowser\"; }"
"{ LSHandlerContentType = \"public.xhtml\"; LSHandlerPreferredVersions =  { LSHandlerRoleAll = \"-\"; }; LSHandlerRoleAll = \"$defaultBrowser\"; }"
"{ LSHandlerContentType = \"public.html\"; LSHandlerPreferredVersions =  { LSHandlerRoleAll = \"-\"; }; LSHandlerRoleAll = \"$defaultBrowser\"; }"
"{ LSHandlerPreferredVersions = { LSHandlerRoleAll = \"-\"; }; LSHandlerRoleAll = \"$defaultBrowser\"; LSHandlerURLScheme = https; }"
"{ LSHandlerPreferredVersions = { LSHandlerRoleAll = \"-\"; }; LSHandlerRoleAll = \"$defaultBrowser\"; LSHandlerURLScheme = http; }"
)

# lsregister location (this location appears to exist on most macOS systems)
lsregister='/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister'
# This is an alternate location, but I think anything with the location below should also have the location above
#lsregister='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

# Double-check the plistLocation exists
if [[ -f "$plistLocation" ]]
	then
		# Initialize counter that will just keep moving us through the array of dicts
		# Count up until we get to a blank dict. This is the total number in the plist.
		countUp=0

		until [[ "$dictCount" == *'", Does Not Exist'* ]]
			do
				dictCount=$(2>&1 "$plistBuddy" -c "Print LSHandlers:$countUp" "$plistLocation")
				countUp=$((countUp+1))
			done
		# Interate down through the plist, removing any matching dicts. This will prevent a 
		# situation where the deleted dict's address is taken over by the one following it.
		# Otherwise, the moved dict is missed and this process is incomplete.
		countDown="$countUp"
		until [[ "${countDown}" == -1 ]]	
			do
				dictResult=$(2>&1 "$plistBuddy" -c "Print LSHandlers:$countDown" "$plistLocation")
				# Check for existing settings
				if [[ "$dictResult" == *"public.url"* ]] || [[ "$dictResult" == *"public.html"* ]] || [[ "$dictResult" == *"LSHandlerURLScheme = https"* ]] || [[ "$dictResult" == *"LSHandlerURLScheme = http"* ]] || [[ "$dictResult" == *"public.xhtml"* ]]
					then
						# Delete the existing. We'll add new ones in later
			         	"$plistBuddy" -c "Delete LSHandlers:$countDown" "$plistLocation"
			         	/bin/echo "Deleting LSHandlers:$countDown from Plist"
				fi

				# Decrease counter
				countDown=$((countDown-1))
			done
	else
		# Say the Plist does not exist
		/bin/echo "Plist does not exist. Creating directory for it."
		/bin/mkdir -p "$plistDirectory"

fi

/bin/echo "Adding in prefs"
for preference in "${prefsToAdd[@]}"
	do
		/usr/bin/defaults write "$plistLocation" LSHandlers -array-add "$preference"
	done

/usr/sbin/chown "${consoleUser}":"staff" "$plistLocation"

# Check the lsregister location exists
if [[ -f "$lsregister" ]]
	then
		/bin/echo "Rebuilding Launch services. This may take a few moments."
		# Rebuilding launch services
		sudo -u "${consoleUser}" "$lsregister" -kill -r -domain local -domain system -domain user
	else
		/bin/echo "You may need to log out or reboot for changes to take effect. Cannot find location of lsregister at $lsregister"
fi

exit 0
