#!/bin/sh

USER_ID=`id -u`

if [ "$USER_ID" -ne 0 ]; then
    echo "You must be root to run the script. Use sudo $0"
    exit
fi

install_dir=/Applications/GlobalProtect.app/Contents/Resources
app_log_dir=/Library/Logs/PaloAltoNetworks/GlobalProtect

mkdir -p "$app_log_dir"

((

    checkAndWaitProcess()
    {
        if [[ "$2" ]]; then
            T="$2"
        else
            T=5
        fi
        
        C=0
        while [[ C -lt $T ]] && 
              ( killall -s "$1" >/dev/null 2>/dev/null )
        do
            let C=C+1
            sleep 1
        done

        killall -s $1 >/dev/null 2>/dev/null
        return $?
    }

    pan_info()
    {
        curtime=`date`
        echo $curtime ' ' $1 >> ${app_log_dir}/PanGPInstall.log
    }

    curver=`defaults read ${install_dir}/../Info CFBundleShortVersionString`

    if [[ "$HOME" ]]; then
        USER=`stat -f "%Su" "$HOME"`
        pan_info "Uninstalling GlobalProtect version ${curver}, user ${USER}"    
        pan_info "unload user gps, gpa"
        sudo -u"$USER" launchctl remove com.paloaltonetworks.gp.pangps
        sudo -u"$USER" launchctl remove com.paloaltonetworks.gp.pangpa
    else
        pan_info "Uninstalling GlobalProtect version ${curver}"    
    fi

    pan_info "unload gps, gpsd and gpa"
    launchctl remove com.paloaltonetworks.gp.pangpa
    launchctl remove com.paloaltonetworks.gp.pangps
    launchctl remove com.paloaltonetworks.gp.pangpsd
    
    #wait for 15 sec. while PanGPS quits
    if checkAndWaitProcess "PanGPS" 5; then
        pan_info "PanGPS didn't quit within 5 sec. Killing"
        killall -15 PanGPS
        if checkAndWaitProcess "PanGPS" 5; then
            pan_info "PanGPS didn't quit after kill within 5 sec."
        fi
    fi
    
    #wait for 5 sec. while GlobalProtect quits
    if checkAndWaitProcess "GlobalProtect" 5; then
        pan_info "GlobalProtect didn't quit within 5 sec. Killing"
        killall -15 GlobalProtect
        if checkAndWaitProcess "GlobalProtect" 5; then
            pan_info "GlobalProtect didn't quit after kill within 5 sec."
        fi
    fi

    pan_info "Cleanup Dynamic Store"    
    echo "remove State:/Network/Service/gpd.pan/IPv4" | scutil 
    echo "remove State:/Network/Service/gpd.pan/DNS"  | scutil 

    pan_info "rm all"
    rm -f "/Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist"
    rm -f "/Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist"
    rm -f "/Library/LaunchDaemons/com.paloaltonetworks.gp.pangpsd.plist"

    rm -rf "/Library/Application Support/PaloAltoNetworks/GlobalProtect"
    rm -rf "/Applications/GlobalProtect.app"
    rm -rf "/Applications/GlobalProtect.app.bak"
    rm -rf "/System/Library/Extensions/gplock"*.kext
    rm -rf "/Library/Extensions/gplock"*.kext

    #Mercy kill if processes are stuck
    killall -9 GlobalProtect
    killall -9 PanGPS

    rm -rf /Library/Preferences/com.paloaltonetworks.GlobalProtect*
    rm -rf /Library/Preferences/PanGPS*
    if [[ "$HOME" ]]; then
        rm -rf "$HOME/Library/Application Support/PaloAltoNetworks/GlobalProtect"
        rm -rf "$HOME"/Library/Preferences/com.paloaltonetworks.GlobalProtect*
        rm -rf "$HOME"/Library/Preferences/PanGPS*
        #remove password entry from keychain
        security delete-generic-password -l GlobalProtect -s GlobalProtect
    fi

    pan_info "Unload driver"
    ifconfig gpd0 down
    kextunload -b com.paloaltonetworks.kext.pangpd
    
    pan_info "Unload gplock"
    kextunload -b com.paloaltonetworks.GlobalProtect.gplock

    #10.9 addition to clear system preferences cache
    killall -SIGTERM cfprefsd
        
    pan_info "uninstall packages from globalprotect"
    for pkg in `pkgutil --pkgs |grep com.paloaltonetworks.globalprotect`
    do 
        pkgutil --forget "$pkg"
    done
    rm -rf /Library/Logs/PaloAltoNetworks/GlobalProtect/*

    echo "Uninstallation finished."

)  2>&1) >> ${app_log_dir}/PanGPInstall.log
