#!/bin/bash

log() {
    echo "$1"
    /usr/bin/logger -t "NoMAD Installer:" "$1"
}
log "Installing NoMAD.app"

tempDir=$(/usr/bin/mktemp -d -t "NoMAD_Installer")

cleanUp() {
    log "Performing cleanup tasks..."
    /bin/rm -r "$tempDir"
}

trap cleanUp exit

if [[ -z "$4" ]]; then
    packageDownloadUrl="https://files.nomad.menu/NoMAD.pkg"
else
    packageDownloadUrl="$4"
fi

loggedInUserPid=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; username = SCDynamicStoreCopyConsoleUser(None, None, None)[1]; print(username);')

launchctlCmd=$(/usr/bin/python -c 'import platform; from distutils.version import StrictVersion as SV; print("asuser") if SV(platform.mac_ver()[0]) >= SV("10.10") else "bsexec"')

log "Downloading NoMAD.pkg..."
/usr/bin/curl -s $packageDownloadUrl -o "$tempDir/NoMAD.pkg"
if [ $? -ne 0 ]; then
    log "curl error: The package did not successfully download"; exit 1
fi

pkgSignatureCheck=$(/usr/sbin/pkgutil --check-signature "$tempDir/NoMAD.pkg")
if [ $? -ne 0 ]; then
    log "pkgutil error: The downloaded package did not pass the signature check"; exit 1
fi

log "Installing NoMAD.app..."
/usr/sbin/installer -pkg "$tempDir/NoMAD.pkg" -target /
if [ $? -ne 0 ]; then
    log "installer error: The package did not successfully install"; exit 1
fi

log "Writing LaunchAgent..."
read -d '' launchAgent <<"EOF"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>com.trusourcelabs.NoMAD</string>
        <key>LimitLoadToSessionType</key>
        <array>
        <string>Aqua</string>
        </array>
        <key>ProgramArguments</key>
        <array>
        <string>/Applications/NoMAD.app/Contents/MacOS/NoMAD</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
</plist>
EOF
echo "$launchAgent" > /Library/LaunchAgents/com.trusourcelabs.NoMAD.plist

/usr/sbin/chown root:wheel /Library/LaunchAgents/com.trusourcelabs.NoMAD.plist
/bin/chmod 644 /Library/LaunchAgents/com.trusourcelabs.NoMAD.plist

log "Loading LaunchAgent..."
/bin/launchctl "$launchctlCmd" "$loggedInUserPid" /bin/launchctl load /Library/LaunchAgents/com.trusourcelabs.NoMAD.plist
if [ $? -ne 0 ]; then
    log "launchctl error: The LaunchAgent failed to load"; exit 1
fi

log "NoMAD.app install complete"
exit 0
