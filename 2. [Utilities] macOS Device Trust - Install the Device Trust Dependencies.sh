#!/bin/sh

## Get current user
currentUser=$(/usr/bin/stat -f "%Su" "/dev/console")

echo "Running pip3 install --upgrade pip"

sudo pip3 install --upgrade pip

echo "Running pip3 install pyobjc-framework-SystemConfiguration"

sudo pip3 install pyobjc-framework-SystemConfiguration

##Delete current keychain if listed

sudo -u "$currentUser" security delete-keychain okta.keychain

exit
