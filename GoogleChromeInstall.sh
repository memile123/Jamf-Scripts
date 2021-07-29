#!/bin/sh

pkgfile="googlechrome.pkg"
logfile="/Library/Logs/GoogleChromeInstallScript.log"

url='https://dl.google.com/chrome/mac/universal/stable/gcem/GoogleChrome.pkg'


/bin/echo "--" >> ${logfile}
/bin/echo "`date`: Downloading latest version." >> ${logfile}
/usr/bin/curl -s -o /tmp/${pkgfile} ${url}
/bin/echo "`date`: Installing pkg." >> ${logfile}
installer -pkg /tmp/${pkgfile} -target /


exit 0
