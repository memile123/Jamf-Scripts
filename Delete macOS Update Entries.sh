#!/bin/bash

sudo rm -rf "/macOS Install Data"
sudo rm /Library/Preferences/com.apple.SoftwareUpdate.plist
sudo launchctl kickstart -k system/com.apple.softwareupdated
