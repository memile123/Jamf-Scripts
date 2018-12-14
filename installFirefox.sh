#!/usr/bin/env bash
# Connor Sanders June 2018
# Assuming Hard Drive name is Macintosh HD

# Downloads and silently latest installer from Firefox site
dmgName="Firefox.dmg"
VolumeName="Firefox"
targetDrive="/Volumes/Macintosh HD"
downloadURL="https://download.mozilla.org/?product=firefox-latest-ssl&os=osx&lang=en-US"
appName="Firefox.app"

# Downloading File
echo "Downloading DMG File..."
	curl -s -L -o "/tmp/$dmgName" "$downloadURL"

### Below commands installs DMG in silent mode ###
# Mounts DMG File
echo "Mounting DMG FIle..."
	hdiutil mount /tmp/$dmgName -nobrowse -quiet
# Installs pkg contained inside DMG
echo "Installing DMG..."
  	cp -r /Volumes/"${VolumeName}"/"${appName}" /Applications/Firefox.app
# Unmount DMG
echo "Unmounting DMG..."
	hdiutil unmount /Volumes/"${VolumeName}"
	sleep 5
# Deletes tmp file
echo "Deleting DMG File"
	rm /tmp/$dmgName

echo "Install Complete."
	exit 0
