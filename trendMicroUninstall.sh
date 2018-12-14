#!/bin/sh


# Copyright:       EVRY
# Filename:        UninstallTrend.sh
# Requires:        -
# Purpose:         Removes Trend Micro Security
# Contact:        Anders Holmdahl <anders.holmdahl@evry.com>
# Mod history:    2018-01-31

launchctl unload /Library/LaunchDaemons/com.trendmicro.icore.av.plist
rm /Library/LaunchDaemons/com.trendmicro.*
rm -r "/Library/Application Support/TrendMicro"
rm -r /Library/Frameworks/TMAppCommon.framework
rm -r /Library/Frameworks/TMAppCore.framework
rm -r /Library/Frameworks/TMGUIUtil.framework
rm -r /Library/Frameworks/iCoreClient.framework
rm -r /Applications/TrendMicroSecurity.app

killall -kill TmLoginMgr
killall -kill UIMgmt
