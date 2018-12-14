#!/bin/sh

#gets current logged in user
getUser=$(ls -l /dev/console | awk '{ print $3 }')

#gets named
firstInitial=$(finger -s $getUser | head -2 | tail -n 1 | awk '{print tolower($2)}' | cut -c 1)
lastName=$(finger -s $getUser | head -2 | tail -n 1 | awk '{print tolower($3)}')
computerName=$firstInitial$lastName"-mac"

#set all the name in all the places
scutil --set ComputerName "$computerName"
scutil --set LocalHostName "$computerName"
scutil --set HostName "$computerName"
