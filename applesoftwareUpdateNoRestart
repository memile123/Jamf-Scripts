#!/bin/sh

NoRestartUpdates=`/usr/sbin/softwareupdate -l | /usr/bin/grep -v restart | /usr/bin/grep -B1 recommended | /usr/bin/grep -v recommended | /usr/bin/awk '{print $2}' | /usr/bin/awk '{printf "%s ", $0}'`

/usr/sbin/softwareupdate -i $NoRestartUpdates
/usr/local/bin/jamf recon

exit 0
