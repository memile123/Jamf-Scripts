#!/bin/sh
if [ -z $3 ]; 
    then 
        currentUser=`stat -f '%Su' /dev/console` 
    else 
        currentUser=$3 
fi 

# Add the current user to the local admin group on the Mac

dseditgroup -o edit -a $currentUser -t user admin

if [ "$?" == "0" ];
    then
        echo "Successfully added $currentUser to admin group"
    else
        echo "ERROR: Unable to add $currentUser to admin group"
        exit 1
fi

exit 0
