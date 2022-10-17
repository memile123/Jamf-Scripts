#!/bin/bash
# Best used with an admin account that has a securetoken

echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
        <dict>
                <key>Username</key>
                <string>AdminUser</string>
                <key>Password</key>
                <string>AdminPassword</string>
        </dict>
</plist>' > /tmp/filevault.plist
fdesetup disable -inputplist < /tmp/filevault.plist
rm /tmp/filevault.plist
