#!/bin/bash

# disable indexing of the root volume

mdutil -i off

echo "Indexing has been disabled"

# reset the data cache for your Mac’s hard drive:

mdutil -E /

echo "Data cache has been deleted"

#re-indexing your hard drive

mdutil -i on /

echo "Re-indexing your hard drive"

/usr/sbin/jamf displayMessage -message "The Spotlight index has been reset for your computer. It may take a few hours to completely reindex your hard drive"

exit 0
