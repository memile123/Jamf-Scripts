#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Jamf policy parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Link must be a direct link to the file.
# e.g. 	https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg
# For security's sake, ONLY USE HTTPS LINKS FROM KNOWN GOOD VENDOR SOURCES
# A null $4 returns an errors
# in Jamf, parameters 1–3 are predefined as mount point, computer name, and username
downloadUrl="$4"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check to see if values are added in Jamf policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -z "$4" ]; then
		printf "Parameter 4 is empty. %s\n" "Populate parameter 4 with the package download URL."
		exit 3
fi
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

timeStamp=$(date +"%F %T")

# Get the download file name
pkgName=$(basename "$downloadUrl")

# Directory where the file will be downloaded to
downloadDirectory="PATH Where to downoad the files to"

# Directory where DMG would be mounted to
dmgMount="$downloadDirectory/mount"


# Get download file extension
downloadExt="${pkgName##*.}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

createDirectory() {
    if [ ! -d $1 ]
        then
        mkdir -p $1
    fi
}

cleanUp(){
	for filename in $downloadDirectory/*; do
		rm -rf $filename
	done
}

installDmg() {
		# If container is a .dmg:
			# Mount installer container
			# -nobrowse to hide the mounted .dmg
			# -noverify to skip .dmg verification
			# -mountpoint to specify mount point
			hdiutil attach $downloadDirectory/$pkgName -nobrowse -noverify -mountpoint $dmgMount
			if [ -e "$dmgMount"/*.app ]; then
				printf "Found .app inside DMG \n"
      			cp -pPR "$dmgMount"/*.app /Applications
    		elif [ -e "$dmgMount"/*.pkg ]; then
    			print "Found .pkg inside dmg \n"
      			pkgName=$(ls -1 "$dmgMount" | grep .pkg | head -1)
      			installer -allowUntrusted -verboseR -pkg "$dmgMount"/"$pkgName" -target /
    		fi
    		hdiutil detach $dmgMount
}

installApplication() {
	case $downloadExt in
		pkg)
			# Install package
			installer -allowUntrusted -verboseR -pkg "$downloadDirectory"/"$pkgName" -target / 
			installerExitCode=$?
				if [ "$installerExitCode" -ne 0 ]; then
					printf "Failed to install: %s\n" "$pkgName"
					printf "Installer exit code: %s\n" "$installerExitCode"
					exit 2
				fi
			;;
		app) 
			cp -pPR "$dmgMount"/*.app /Applications
			;;
		dmg)
			installDmg
			;;
		*)
			printf "$timeStamp %s\n" "Downloaded $pkgName from..."
			printf "$timeStamp %s\n" "$downloadUrl"
			printf "$timeStamp %s\n" "is an unknown file type."
			rm -rf "$downloadDirectory"/"$pkgName"
			printf "$timeStamp %s\n" "Deleted $downloadFile."
			exit 4
	esac

}

downloadFile() {
	createDirectory $downloadDirectory #Create directory $downloadDirectory, continue if directory already exists
	cd $downloadDirectory
	printf "Downloading File....\n" # Print message
	curl $downloadUrl -O -L #Download file without changing its name.
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# BLAST OFF!!
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

printf "Current working extension: $downloadExt \n"
downloadFile
installApplication
cleanUp

exit 0
