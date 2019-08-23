#!/bin/sh

#Use these commands to edit the NoMad defaults. Always test, test, test, test!

#get username
user=`stat -f "%Su" /dev/console`

sudo -u $user defaults write com.trusourcelabs.NoMAD ADDomain -string "SERVER.COMPANY.COM"
sudo -u $user defaults write com.trusourcelabs.NoMAD GetHelpOptions -string "mailto:help@company.com"
sudo -u $user defaults write com.trusourcelabs.NoMAD GetHelpType -string URL
sudo -u $user defaults write com.trusourcelabs.NoMAD HideGetSoftware 1
sudo -u $user defaults write com.trusourcelabs.NoMAD HidePrefs 1
sudo -u $user defaults write com.trusourcelabs.NoMAD HideQuit 1
sudo -u $user defaults write com.trusourcelabs.NoMAD LocalPasswordSync 1
sudo -u $user defaults write com.trusourcelabs.NoMAD LocalPasswordSyncDontSyncLocalUsers -array admin support
sudo -u $user defaults write com.trusourcelabs.NoMAD MenuGetSoftware -string "Self Service"
sudo -u $user defaults write com.trusourcelabs.NoMAD MenuHomeDirectory -string "Home Drive"
sudo -u $user defaults write com.trusourcelabs.NoMAD MessagePasswordChangePolicy -string "Please ensure your password is not one you've used previously and is a minimum of 8 characters including at least 3 of the following: upper case letter, lower case letter, number or symbol. Your password may not contain your username or any other common words."
sudo -u $user defaults write com.trusourcelabs.NoMAD PersistExpiration 1
sudo -u $user defaults write com.trusourcelabs.NoMAD TitleSignIn -string "Please Enter Your Comapny Credentials"
sudo -u $user defaults write com.trusourcelabs.NoMAD ShowHome 1
sudo -u $user defaults write com.trusourcelabs.NoMAD SignInWindowOnLaunch 1
sudo -u $user defaults write com.trusourcelabs.NoMAD UPCAlert 1 
sudo -u $user defaults write com.trusourcelabs.NoMAD UseKeychain 1
