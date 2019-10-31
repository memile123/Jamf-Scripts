#!/bin/bash


# If app is open, alert user with the option to quit the app or defer for later. If user chooses to install it will quit the app, trigger the installation,
# then alert the user the policy is complete with the option to reopen the app. If the app is not open it will trigger the installation without alerting
# Quit and Open path have 2 entries for the times you are quiting/uninstalling an old version of an app that is replaced by a new name (for example quiting Adobe Acrobat Pro, which is replaced by Adobe Acorbat.app)

################################DEFINE VARIABLES################################

# $4 = Title
# $5 = App ID
# $6 = Process Name
# $7 = Jamf Policy Event
# $8 = Quit App Path
# $9 = Open App Path

#Defining the Sender ID as self service due to setting the Sender ID as the actual app being updated would often cause the app to crash
sender="$5"
#Jamf parameters can't be passed into a function, redefining the app path to be used within the funciton
quitPath="$8"
openPath="$9"

################################SETUP FUNCTIONS TO CALL################################

fGetCurrenUser (){
currentUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

  # Identify the UID of the logged-in user
  currentUserUID=`id -u "$currentUser"`
}

fQuitApp (){
cat > /private/tmp/quit_application.sh <<EOF
#!/bin/bash

/bin/launchctl asuser "$currentUserUID" /usr/bin/osascript -e 'tell application "$quitPath" to quit'
EOF

/bin/chmod +x /private/tmp/quit_application.sh
/bin/launchctl asuser "$currentUserUID" sudo -iu "$currentUser" "/private/tmp/quit_application.sh"
/bin/rm -f "/private/tmp/quit_application.sh"
}

fOpenApp (){
  cat > /private/tmp/open_application.sh <<EOF
#!/bin/bash

/usr/bin/open "$openPath"
EOF

/bin/chmod +x /private/tmp/open_application.sh
/bin/launchctl asuser "$currentUserUID" sudo -iu "$currentUser" "/private/tmp/open_application.sh"
/bin/rm -f "/private/tmp/open_application.sh"
}

################################SETUP TIMER FILE################################

## Set up the software update time if it does not exist already
if [ ! -e /Library/Application\ Support/JAMF/.$5.timer.txt ]; then
  echo "2" > /Library/Application\ Support/JAMF/.$5.timer.txt
fi

## Get the timer value
timer=`cat /Library/Application\ Support/JAMF/.$5.timer.txt`

################################ALERTER MESSAGE OPTIONS################################

saveQuitMSG="must be quit in order to update. Save all data before quitting."
updatedMSG="has been updated. Thank you."

################################START 'UPDATE WITH ALERTER' PROCESS################################

# Look if app is open via process name
appOpen="$(pgrep -ix "$6" | wc -l)"

# if the app is open and the defer timer is not zero
if [[ $appOpen -gt 0 && $timer -gt 0 ]]; then
    fGetCurrenUser
    updateAnswer="$(/bin/launchctl asuser "$currentUserUID" /Library/Application\ Support/JAMF/alerter -title "$4" -sender "$sender" -message "$saveQuitMSG" -closeLabel "Defer ($timer)" -actions "Quit & Update" -timeout 3600)"
    if [[ $updateAnswer == "Quit & Update" ]]; then
        #quit app, install the update, then prompt the user when complete and ask if they want to reopen the app. Message will time out after 60 secs.
        fQuitApp
        /usr/local/bin/jamf policy -event "$7"
        reopenAnswer="$(/bin/launchctl asuser "$currentUserUID" /Library/Application\ Support/JAMF/alerter -title "$4" -sender "$sender" -message "$updatedMSG" -closeLabel Ok -actions Reopen -timeout 60)"
        if [[ $reopenAnswer == Reopen ]]; then
            fOpenApp
        fi
        #reset timer after updating
        echo "2" > /Library/Application\ Support/JAMF/.$5.timer.txt

    else
        let CurrTimer=$timer-1
        echo "User chose to defer"
        echo "$CurrTimer" > /Library/Application\ Support/JAMF/.$5.timer.txt
        echo "Defer count is now $CurrTimer"
        exit 0
    fi
# if app is open and defer timer has run out
elif [[ $appOpen -gt 0 && $timer == 0 ]]; then
    fGetCurrenUser
    /bin/launchctl asuser "$currentUserUID" /Library/Application\ Support/JAMF/alerter -title "$4" -sender "$sender" -message "$saveQuitMSG" -actions "Quit & Update" -closeLabel "No Deferrals Left " -timeout 3600
    fQuitApp
    /usr/local/bin/jamf policy -event "$7"
    reopenAnswer="$(/bin/launchctl asuser "$currentUserUID" /Library/Application\ Support/JAMF/alerter -title "$4" -sender "$sender" -message "$updatedMSG" -closeLabel Ok -actions Reopen -timeout 60)"
    if [[ $reopenAnswer == Reopen ]]; then
        fOpenApp
    fi
    #reset timer after updating
    echo "2" > /Library/Application\ Support/JAMF/.$5.timer.txt

else
    # app is not open, reset timer and run updates
    echo "2" > /Library/Application\ Support/JAMF/.$5.timer.txt
    /usr/local/bin/jamf policy -event "$7"
fi
