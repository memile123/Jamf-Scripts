#!/bin/bash

LEGACY_INSTPREFIX="/opt/cisco/vpn"
LEGACY_BINDIR="${LEGACY_INSTPREFIX}/bin"

INSTPREFIX="/opt/cisco/anyconnect"
BINDIR="${INSTPREFIX}/bin"
PLUGINDIR="${BINDIR}/plugins"
LIBDIR="${INSTPREFIX}/lib"
PROFDIR="${INSTPREFIX}/profile"
MGMTPROFDIR="${INSTPREFIX}/profile/mgmttun"
SCRIPTDIR="${INSTPREFIX}/script"
HELPDIR="${INSTPREFIX}/help"
KEXTDIR="/Library/Extensions"
APPDIR="/Applications/Cisco"
GUIAPP="Cisco AnyConnect Secure Mobility Client.app"
UNINSTALLER="Uninstall AnyConnect.app"
INITDIR="/System/Library/StartupItems"
INIT="vpnagentd"
LAUNCHD_DIR="/Library/LaunchDaemons"
LAUNCHD_FILE="com.cisco.anyconnect.vpnagentd.plist"
LAUNCHD_AGENT_DIR="/Library/LaunchAgents"
LAUNCHD_AGENT_GUI_FILE="com.cisco.anyconnect.gui.plist"
LAUNCHD_AGENT_NOTIFICATION_FILE="com.cisco.anyconnect.notification.plist"
ACMANIFESTDAT="${INSTPREFIX}/VPNManifest.dat"
VPNMANIFEST="ACManifestVPN.xml"
UNINSTALLLOG="/tmp/vpn-uninstall.log"

ANYCONNECT_VPN_PACKAGE_ID=com.cisco.pkg.anyconnect.vpn

# Array of files to remove
FILELIST=("${BINDIR}/vpnagentd" \
          "${BINDIR}/vpn_uninstall.sh" \
          "${BINDIR}/anyconnect_uninstall.sh" \
          "${BINDIR}/vpnui" \
          "${BINDIR}/vpn" \
          "${BINDIR}/vpnmgmttun" \
          "${BINDIR}/acinstallhelper" \
          "${BINDIR}/vpndownloader.app" \
          "${BINDIR}/UpdateComponentManifest.json" \
          "${BINDIR}/Cisco AnyConnect Secure Mobility Client Notification.app" \
          "${LEGACY_BINDIR}/vpndownloader.app" \
          "${LEGACY_BINDIR}/vpndownloader.sh" \
          "${LEGACY_BINDIR}/manifesttool" \
          "${LEGACY_BINDIR}/vpn_uninstall.sh" \
          "${INSTPREFIX}/AnyConnectLocalPolicy.xsd" \
          "${INSTPREFIX}/gui_keepalive" \
          "${INSTPREFIX}/OpenSource.html" \
          "${LEGACY_INSTPREFIX}/update.txt" \
          "${INSTPREFIX}/update.txt" \
          "${INSTPREFIX}/${VPNMANIFEST}" \
          "${LIBDIR}/libacciscossl.dylib" \
          "${LIBDIR}/libacciscocrypto.dylib" \
          "${LIBDIR}/libaccurl.4.dylib" \
          "${LIBDIR}/libboost_filesystem.dylib" \
          "${LIBDIR}/libboost_system.dylib" \
          "${LIBDIR}/libboost_thread.dylib" \
          "${LIBDIR}/libboost_date_time.dylib" \
          "${LIBDIR}/libboost_signals.dylib" \
          "${LIBDIR}/libboost_chrono.dylib" \
          "${LIBDIR}/libvpnagentutilities.dylib" \
          "${LIBDIR}/libvpncommon.dylib" \
          "${LIBDIR}/libvpncommoncrypt.dylib" \
          "${LIBDIR}/libvpnapi.dylib" \
          "${LIBDIR}/libac_sock_fltr_api.dylib" \
          "${LIBDIR}/libacruntime.dylib" \
          "${PLUGINDIR}/libvpnipsec.dylib" \
          "${PLUGINDIR}/libacfeedback.dylib" \
          "${PLUGINDIR}/libvpnapishim.dylib" \
          "${PLUGINDIR}/libacdownloader.dylib" \
          "${PROFDIR}/AnyConnectProfile.xsd" \
          "${MGMTPROFDIR}/AnyConnectProfile.xsd" \
          "${LAUNCHD_DIR}/${LAUNCHD_FILE}" \
          "${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_GUI_FILE}" \
          "${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_NOTIFICATION_FILE}" \
          "${INITDIR}/${INIT}" \
          "${APPDIR}/${GUIAPP}" \
          "${APPDIR}/${UNINSTALLER}" \
          "${KEXTDIR}/acsock.kext")

echo "Uninstalling Cisco AnyConnect Secure Mobility Client..."
echo "Uninstalling Cisco AnyConnect Secure Mobility Client..." > "${UNINSTALLLOG}"
echo `whoami` "invoked $0 from " `pwd` " at " `date` >> "${UNINSTALLLOG}"

# Check for root privileges
if [ `whoami` != "root" ]; then
  echo "Sorry, you need super user privileges to run this script."
  echo "Sorry, you need super user privileges to run this script." >> "${UNINSTALLLOG}"
  exit 1
fi

IS_UPGRADE=${1-false}

# update the VPNManifest.dat; if no entries remain in the .dat file then
# this tool will delete the file - DO NOT blindly delete VPNManifest.dat by
# adding it to the FILELIST above - allow this tool to delete the file if needed
if [ -f "${BINDIR}/manifesttool" ]; then
  echo "${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${VPNMANIFEST}" >> "${UNINSTALLLOG}"
  ${BINDIR}/manifesttool -x ${INSTPREFIX} ${INSTPREFIX}/${VPNMANIFEST}
fi

# check the existence of the manifest file - if it does not exist, remove the manifesttool, setuidtool
if [ ! -f ${ACMANIFESTDAT} ]; then
  if [ -f ${BINDIR}/manifesttool ]; then
    echo "Removing ${BINDIR}/manifesttool" >> "${UNINSTALLLOG}"
    rm -f ${BINDIR}/manifesttool
  fi
  if [ -f ${BINDIR}/SetUIDTool ]; then
    echo "Removing ${BINDIR}/SetUIDTool" >> "${UNINSTALLLOG}"
    rm -f ${BINDIR}/SetUIDTool
  fi
fi

OS_VER=$(sw_vers -productVersion | awk -F. '{ print $2; }')
MYUID=`echo "show State:/Users/ConsoleUser" | scutil | awk '/UID/ { print $3 }'`

# Unload the GUI launch agent if it exists
if [ -e ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_GUI_FILE} ] ; then 
    echo "Stopping GUI launch agent..." >> "${UNINSTALLLOG}"
    logger "Stopping the GUI launch agent..."
    if [[ "$OS_VER" -ge 11 ]]; then
        # Use new launchctl subcommand for 10.11 and higher
        echo "launchctl bootout gui/${MYUID} ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_GUI_FILE}" >> "${UNINSTALLLOG}"
        launchctl bootout gui/${MYUID} ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_GUI_FILE} >> "${UNINSTALLLOG}" 2>&1
    else
        # Use legacy launchctl subcommand on earlier OS X
        echo "sudo -u #${MYUID} launchctl unload -S Aqua ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_GUI_FILE}" >> "${UNINSTALLLOG}"
        sudo -u \#${MYUID} launchctl unload -S Aqua ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_GUI_FILE} >> "${UNINSTALLLOG}" 2>&1
    fi
fi

# Unload the Notification launch agent if it exists
if [ -e ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_NOTIFICATION_FILE} ] ; then
    echo "Stopping Notification launch agent..." >> "${UNINSTALLLOG}"
    logger "Stopping the Notification launch agent..."
    if [[ "$OS_VER" -ge 11 ]]; then
        # Use new launchctl subcommand for 10.11 and higher
        echo "launchctl bootout gui/${MYUID} ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_NOTIFICATION_FILE}" >> "${UNINSTALLLOG}"
        launchctl bootout gui/${MYUID} ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_NOTIFICATION_FILE} >> "${UNINSTALLLOG}" 2>&1
    else
        # Use legacy launchctl subcommand on earlier OS X
        echo "sudo -u #${MYUID} launchctl unload -S Aqua ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_NOTIFICATION_FILE}" >> "${UNINSTALLLOG}"
        sudo -u \#${MYUID} launchctl unload -S Aqua ${LAUNCHD_AGENT_DIR}/${LAUNCHD_AGENT_NOTIFICATION_FILE} >> "${UNINSTALLLOG}" 2>&1
    fi
fi

# ensure that the gui are not running
OURPROCS=`ps -A -o pid,command | egrep '(Cisco AnyConnect Secure Mobility Client)' | egrep -v 'grep|vpn_uninstall|anyconnect_uninstall' | awk '{print $1}'`
if [ -n "${OURPROCS}" ] ; then
    for DOOMED in ${OURPROCS}; do
        echo Killing `ps -A -o pid,command -p ${DOOMED} | grep ${DOOMED} | egrep -v 'ps|grep'` >> "${UNINSTALLLOG}"
        kill -INT ${DOOMED} >> "${UNINSTALLLOG}" 2>&1
    done
fi

# Wait one second to allow the GUI to properly close. This hack
# prevents some IPC issues related to trying to close the GUI and agent
# almost simultaneously.
sleep 1

# Remove the plugins directory
if [ -e ${PLUGINDIR} ] ; then
  echo "rm -rf "${PLUGINDIR}"" >> "${UNINSTALLLOG}"
  rm -rf "${PLUGINDIR}" >> "${UNINSTALLLOG}" 2>&1
fi

# Remove the vpnagent init scripts.  Attempt to disable agent first.
# If the old StartupItems file exists, try to use that method to stop the agent
if [ -e ${INITDIR}/${INIT}/${INIT} ] ; then
    echo "Stopping agent..." >> "${UNINSTALLLOG}"
    echo "${INITDIR}/${INIT}/${INIT} stop" >> "${UNINSTALLLOG}"
    logger "Stopping the VPN agent..."
    ${INITDIR}/${INIT}/${INIT} stop >> "${UNINSTALLLOG}" 2>&1
fi

# If the new launchd file exists, try to use that method to stop the agent
if [ -e ${LAUNCHD_DIR}/${LAUNCHD_FILE} ] ; then
    echo "Stopping agent..." >> "${UNINSTALLLOG}"
    logger "Stopping the VPN agent..."
    if [[ "$OS_VER" -ge 11 ]]; then
        # Use new launchctl subcommand for 10.11 and higher
        echo "launchctl bootout system ${LAUNCHD_DIR}/${LAUNCHD_FILE}" >> "${UNINSTALLLOG}"
        launchctl bootout system ${LAUNCHD_DIR}/${LAUNCHD_FILE} >> "${UNINSTALLLOG}" 2>&1
    else
        # Use legacy launchctl subcommand on earlier OS X
        # IMPORTANT: The use of sudo here is necessary to ensure that we communicate
        #  with the global instance of launchd. Without the sudo, the uninstall will fail
        #  when initiated from the GUI. This appears to be due to launchctl working
        #  based on the UID, rather than the EUID. The GUI program will only set the
        #  EUID to root, while the UID remains as the user.
        echo "sudo launchctl unload ${LAUNCHD_DIR}/${LAUNCHD_FILE}" >> "${UNINSTALLLOG}"
        sudo launchctl unload ${LAUNCHD_DIR}/${LAUNCHD_FILE} >> "${UNINSTALLLOG}" 2>&1
    fi
fi

case "${1}" in
    noblock)
    echo "uninstalling immediately..." >> "${UNINSTALLLOG}"
    ;;

    *)

    max_seconds_to_wait=10
    ntests=$max_seconds_to_wait
    # Wait up to max_seconds_to_wait seconds for the agent to finish.
    while [ -n "`ps -A -o command | grep \"/opt/cisco/anyconnect/bin/${INIT}\" | egrep -v 'grep'`" ]
    do
        ntests=`expr  $ntests - 1`
        if [ $ntests -eq 0 ]; then
            logger "Timeout waiting for agent to stop."
            echo "Timeout waiting for agent to stop." >> "${UNINSTALLLOG}"
            break
        fi
        sleep 1
    done
  ;;
esac

# ensure that the agent, gui and cli are not running - show no mercy
OURPROCS=`ps -A -o pid,command | egrep '(/opt/cisco/anyconnect/bin)|(Cisco AnyConnect Secure Mobility Client)' | egrep -v 'grep|vpn_uninstall|anyconnect_uninstall' | awk '{print $1}'`
if [ -n "${OURPROCS}" ] ; then
    for DOOMED in ${OURPROCS}; do
        echo Killing `ps -A -o pid,command -p ${DOOMED} | grep ${DOOMED} | egrep -v 'ps|grep'` >> "${UNINSTALLLOG}"
        kill -KILL ${DOOMED} >> "${UNINSTALLLOG}" 2>&1
    done
fi

# unload the acsock if it is still loaded by the system
ACSOCKLOADED=`kextstat | grep acsock`
if [ ! "x${ACSOCKLOADED}" = "x" ]; then
  echo "Unloading {KEXTDIR}/acsock.kext" >> "${UNINSTALLLOG}"
  kextunload ${KEXTDIR}/acsock.kext >> "${UNINSTALLLOG}" 2>&1
  echo "${KEXTDIR}/acsock.kext unloaded" >> "${UNINSTALLLOG}"
fi

INDEX=0

# Remove only those files that we know we installed
INDEX=0
while [ $INDEX -lt ${#FILELIST[@]} ] ; do
  echo "rm -rf "${FILELIST[${INDEX}]}"" >> "${UNINSTALLLOG}"
  rm -rf "${FILELIST[${INDEX}]}"
  let "INDEX = $INDEX + 1"
done

# Remove Disable VPN Profile unless an upgrade is in progress
if [ "x${IS_UPGRADE}" != "xtrue" ]; then
  echo "rm -rf \"${PROFDIR}/VPNDisable_ServiceProfile.xml\"" >> "${UNINSTALLLOG}"
  rm -rf "${PROFDIR}/VPNDisable_ServiceProfile.xml"
fi

# Remove the bin directory if it is empty
if [ -e ${BINDIR} ] ; then
  if [ ! -z `find "${BINDIR}" -prune -empty` ] ; then
    echo "rm -df "${BINDIR}"" >> "${UNINSTALLLOG}"
    rm -df "${BINDIR}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# Only remove the Application directory if it is empty
if [ ! -z `find "${APPDIR}" -prune -empty` ] ; then
  echo "rm -rf "${APPDIR}"" >> "${UNINSTALLLOG}"
  rm -rf "${APPDIR}" >> "${UNINSTALLLOG}" 2>&1
fi

# Remove the lib directory if it is empty
if [ -e ${LIBDIR} ] ; then
  if [ ! -z `find "${LIBDIR}" -prune -empty` ] ; then
    echo "rm -df "${LIBDIR}"" >> "${UNINSTALLLOG}"
    rm -df "${LIBDIR}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# Remove the script directory if it is empty
if [ -e ${SCRIPTDIR} ] ; then
  if [ ! -z `find "${SCRIPTDIR}" -prune -empty` ] ; then
    echo "rm -df "${SCRIPTDIR}"" >> "${UNINSTALLLOG}"
    rm -df "${SCRIPTDIR}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# Remove the help directory if it is empty
if [ -e ${HELPDIR} ] ; then
  if [ ! -z `find "${HELPDIR}" -prune -empty` ] ; then
    echo "rm -df "${HELPDIR}"" >> "${UNINSTALLLOG}"
    rm -df "${HELPDIR}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# Remove the management profile directory if it is empty
if [ -e ${MGMTPROFDIR} ] ; then
  if [ ! -z `find "${MGMTPROFDIR}" -prune -empty` ] ; then
    echo "rm -df "${MGMTPROFDIR}"" >> "${UNINSTALLLOG}"
    rm -df "${MGMTPROFDIR}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# Remove the profile directory if it is empty
if [ -e ${PROFDIR} ] ; then
  if [ ! -z `find "${PROFDIR}" -prune -empty` ] ; then
    echo "rm -df "${PROFDIR}"" >> "${UNINSTALLLOG}"
    rm -df "${PROFDIR}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# Remove the legacy bin directory if it is empty
if [ -e ${LEGACY_BINDIR} ] ; then
  if [ ! -z `find "${LEGACY_BINDIR}" -prune -empty` ] ; then
    echo "rm -df "${LEGACY_BINDIR}"" >> "${UNINSTALLLOG}"
    rm -df "${LEGACY_BINDIR}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# Remove the legacy directory if it is empty
if [ -e ${LEGACY_INSTPREFIX} ] ; then
  if [ ! -z `find "${LEGACY_INSTPREFIX}" -prune -empty` ] ; then
    echo "rm -df "${LEGACY_INSTPREFIX}"" >> "${UNINSTALLLOG}"
    rm -df "${LEGACY_INSTPREFIX}" >> "${UNINSTALLLOG}" 2>&1
  fi
fi

# remove installer receipt
pkgutil --forget ${ANYCONNECT_VPN_PACKAGE_ID} >> "${UNINSTALLLOG}" 2>&1

echo "Successfully removed Cisco AnyConnect Secure Mobility Client from the system." >> "${UNINSTALLLOG}"
echo "Successfully removed Cisco AnyConnect Secure Mobility Client from the system."

exit 0
