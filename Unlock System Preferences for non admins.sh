#!/bin/sh

# Unlock System Preferences for non admins.
sudo security authorizationdb write system.preferences allow
sudo security authorizationdb write system.settings allow

# Unlock Date and Time
sudo security authorizationdb write system.preferences.datetime allow
sudo security authorizationdb write system.settings.datetime allow
        
# Unlock Energy Saver preference pane
sudo security authorizationdb write system.preferences.energysaver allow
sudo security authorizationdb write system.settings.energysaver allow

# Unlock Network preference pane
sudo security authorizationdb write system.preferences.network allow
sudo security authorizationdb write system.settings.network allow
sudo security authorizationdb write system.services.systemconfiguration.network allow
/usr/libexec/airportd prefs RequireAdminNetworkChange=NO RequireAdminIBSS=NO
        
# Unlock Print & Scan Preference pane
sudo security authorizationdb write system.preferences.printing allow
sudo security authorizationdb write system.settings.printing allow
        
# Unlock Time Machine preference pane
sudo security authorizationdb write system.preferences.timemachine allow
sudo security authorizationdb write system.settings.timemachine allow

# Give Everyone Print Operator Access
sudo dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
