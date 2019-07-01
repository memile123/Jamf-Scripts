#!/usr/bin/python
#
# preinstall.py
#
#   $Revision:: 6417             $
#   $Author:: eburceanu          $
#   $Date:: 2013-07-17 15:03:56 #$
#
#------------------------------------------------------------------
# Uninstaller
#------------------------------------------------------------------
#
# bdmac@bitdefender.com
# Copyright 2010 Bitdefender. All rights reserved.
#
#   compatibility:  also remove BitDefender if found
#
#   TODO
#   1. launchctl by user
#       $ launchctl list | grep efender
#       -   0   com.bitdefender.avp.antiphishing
#       -   0   com.bitdefender.avod.11.processes
#       -   1   com.bitdefender.avod.05.qss

import os
import shutil
import sys
import plistlib
from optparse import OptionParser
import time
import commands

import subprocess
from subprocess import Popen, PIPE
from time import sleep
import signal
import traceback

import pwd

import socket
import ssl
import httplib

import errno
import json
import urllib2
import urlparse
import pwd, grp
from pwd import getpwnam

import re
import xml.dom.minidom

####### Extract data from projvars.plist ######
SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__)) + "/"

def runBashCommandAndGetOutput(cmd):
    subProc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = subProc.communicate()
    return out.rstrip()

def fetchPlistValue(key, plistFile):
    return runBashCommandAndGetOutput(["/usr/libexec/PlistBuddy -c 'Print {}' {}".format(key, plistFile)])

COMPANY_NAME0 = fetchPlistValue(":COMPANY_NAMES:0", SCRIPT_PATH + "projvars.plist")
COMPANY_NAME1 = fetchPlistValue(":COMPANY_NAMES:1", SCRIPT_PATH + "projvars.plist")
################### The end ###################

parser  = OptionParser(usage = "usage: %prog [options]    \n"
                       "       default options: uninstall   \n"
                       "       \n",
                       version =  "%prog " + " $Rev: 3689 $".strip("$ ").split(' ')[1] )
parser.add_option("-u", "--upgrade",  dest="upgrade",  action='store_true', default=False, help="Use this option to upgrade the product to a newer version. The logs will not be deleted")
parser.add_option("-v", "--verbose", dest="verbose", action='store_true', default=False, help="Run script in verbose mode, showing commands as they are run")

(options, args) = parser.parse_args()

#######

filesAndFolders = [
                   '/Applications/{}'.format(COMPANY_NAME0),
                   '/Library/Application Support/{}/Debug'.format(COMPANY_NAME0),
                   '/Library/Application Support/{}/Errors'.format(COMPANY_NAME0),
                   '/Library/Application Support/{}/History'.format(COMPANY_NAME0),
                   '/Library/Application Support/Antivirus for Mac',
                   '/Library/Application Support/Endpoint Security for Mac',
                   '/Library/{}/AVP'.format(COMPANY_NAME0),
                   '/Library/Receipts/{}Installer.pkg'.format(COMPANY_NAME0),
                   '/Library/Receipts/{}Uninstaller.pkg'.format(COMPANY_NAME0),
                   '/Library/Receipts/{} Installer.pkg'.format(COMPANY_NAME0),
                   '/Library/Receipts/{} Uninstaller.pkg'.format(COMPANY_NAME0),
                   '/Library/Receipts/boms/com.{}.avp.installer.bom'.format(COMPANY_NAME0),
                   '/Library/Receipts/boms/com.{}.avp.uninstall.bom'.format(COMPANY_NAME0),
                   '/Scripts/preinstall',
                   '/Scripts/postinstall',
                   '/Scripts/projvars.plist',
                   '/private/var/db/receipts/com.{}.avp.installer.bom'.format(COMPANY_NAME0),
                   '/private/var/db/receipts/com.{}.avp.installer.plist'.format(COMPANY_NAME0),
                   '/private/var/db/receipts/com.{}.avp.uninstall.bom'.format(COMPANY_NAME0),
                   '/private/var/db/receipts/com.{}.avp.uninstall.plist'.format(COMPANY_NAME0),
                    # temporary files or folders
                   '/private/tmp/postinstallEnt.log',
                   '/private/tmp/ProductVersion.xml',
                   '/private/tmp/com.{}.dmg'.format(COMPANY_NAME0.lower()),
                   '/private/tmp/com.{}.antivirusformac'.format(COMPANY_NAME0.lower()),
                   ]

emptyFolders = [
    '/Scripts',
    '/Library/{}'.format(COMPANY_NAME0)
]

filesAndFolders_upgrade = [
                           '/Library/Application Support/{}/Logs'.format(COMPANY_NAME0),
                           '/Library/Application Support/{}/Crash'.format(COMPANY_NAME0)
                           ]

filesAndFolders_old =   [
                         '/Library/Receipts/boms/com.{}.avp.install.bom'.format(COMPANY_NAME1),
                         '/private/var/db/receipts/com.{}.avp.install.bom'.format(COMPANY_NAME1),
                         '/private/var/db/receipts/com.{}.avp.install.plist'.format(COMPANY_NAME1),
                         ]

links   = [
           '/System/Library/Extensions/IOKitBDAv.kext',
           #    not anymore (beta, internal)
           #'/System/Library/Extensions/BDPRedir.kext',
           '/Library/Mail/Bundles/MailAS.mailbundle',
           '/Library/Application Support/SIMBL/Plugins/safari_antiphishing.bundle',
           ]

daemonPrefix     = [
                    'com.bitdefender.avp',
                    'com.bitdefender.avod',
                    'com.bitdefender.UpdDaemon',
                    'com.bitdefender.Daemon',
                    'com.bitdefender.CoreIssues',
                    ]

bundleIDs   = [
               'com.bitdefender.virusscannerplus',
               'com.bitdefender.antivirusformac',
               'com.bitdefender.EndpointSecurityforMac',
               'com.Bitdefender.avp',
               'com.bitdefender.BitdefenderVirusScanner',
               ]

VirusScannerFiles    = [
                                   '/Library/Application Support/{} Virus Scanner/antivirus.bundle'.format(COMPANY_NAME0),
                                   '/Library/Application Support/{} Virus Scanner/Logs'.format(COMPANY_NAME0),
                                   '/Library/Preferences/com.{}.{}VirusScanner.plist'.format(COMPANY_NAME0.lower(), COMPANY_NAME0),
                                   '/Library/Containers/com.{}.{}VirusScanner'.format(COMPANY_NAME0.lower(), COMPANY_NAME0)
                                   ]

VirusScannerPlusFiles           = [
                                   '/Library/Containers/com.{}.virusscannerplus'.format(COMPANY_NAME0.lower()),
                                   '/Library/Containers/com.{}.VirusScannerHelper'.format(COMPANY_NAME0.lower()),
                                   ]

varRun              = '/private/var/run/'
varTmp              = '/private/var/tmp/'
launchDaemons       = '/Library/LaunchDaemons/'
launchAgents        = '/Library/LaunchAgents/'
preferences         = '/Library/Preferences/'
applications        = '/Applications/'

#######

def log_info( msg ):
	open( "/tmp/preinstallEnt.log", "a+" ).write( time.strftime( "%m/%d/%Y %H:%M:%S" ) + " PREINSTALL INFO: " + msg + "\n" )

def log_warning( msg ):
	open( "/tmp/preinstallEnt.log", "a+" ).write( time.strftime( "%m/%d/%Y %H:%M:%S" ) + " PREINSTALL WARNING: " + msg + "\n" )

def log_error( msg ):
	open( "/tmp/preinstallEnt.log", "a+" ).write( time.strftime( "%m/%d/%Y %H:%M:%S" ) + " PREINSTALL ERROR: " + msg + "\n" )

def RemoveFile(path):
    if os.path.isfile(path):
        os.remove(path)

def RemoveFileOrFolder(path):
    log_info("Remove: " + path)
    if os.path.isfile(path):
        os.remove(path)
    elif os.path.isdir(path):
        shutil.rmtree(path)

def RemoveEmptyFolder(path):
    if os.path.isdir(path) and not os.listdir(path):
        os.rmdir(path)

def RemoveUserFileOrFolder(path):
    usersFolder     = '/Users/'
    userNameList = os.listdir(usersFolder)

    for userName in userNameList:
        if (userName != '.localized') and (userName != 'Shared') and (userName != '.DS_Store'):
            globalPath = usersFolder + userName + path
            log_info(globalPath + "\n")
            RemoveFileOrFolder(globalPath)

def RemFilesAndFolders():
    try:
      rmDriver = os.path.isfile('/private/var/db/receipts/com.{}.avp.installer.plist'.format(COMPANY_NAME0))

      varRunFiles = os.listdir(varRun)
      for varRunFilesNames in varRunFiles:
          if "com.{}".format(COMPANY_NAME0.lower()) in varRunFilesNames:
              os.remove(varRun + varRunFilesNames)


      launchAgentsDaemons = os.listdir(launchAgents) + os.listdir(launchDaemons)

      for daemonName in launchAgentsDaemons:
          if daemonName.startswith('com.bitdefender.avod') or daemonName.startswith('com.bitdefender.avp'):
              agentPath = launchAgents + daemonName
              daemonPath = launchDaemons + daemonName

              if os.path.isfile(agentPath):
                  os.remove(agentPath)

              elif os.path.isfile(daemonPath):
                  os.remove(daemonPath)


      for fileName in filesAndFolders:
          RemoveFileOrFolder(fileName)
          RemoveFileOrFolder(fileName.replace(COMPANY_NAME0, COMPANY_NAME1))
      for path in emptyFolders:
          RemoveEmptyFolder(path)
      for fileName in filesAndFolders_old:
          RemoveFileOrFolder(fileName)

      if not options.upgrade:
          for fileName in filesAndFolders_upgrade:
              RemoveFileOrFolder(fileName)
              RemoveFileOrFolder(fileName.replace(COMPANY_NAME0, COMPANY_NAME1))

      preferenceNames = os.listdir(preferences)

      for prefName in preferenceNames:
          if prefName.startswith("com.bitdefender.avp"):
              os.remove(preferences + prefName)


      appNames = os.listdir(applications)

      for appName in appNames:
          file = applications + appName
          for company in [COMPANY_NAME0, COMPANY_NAME1]:
              if appName.startswith(company) and os.path.isfile(file):
                  os.remove(file)

      if rmDriver:
          for linkName in links:
              if os.path.islink(linkName):
                  os.remove(linkName)

      usersFolder     = '/Users/'
      userNameList = os.listdir(usersFolder)

      for userName in userNameList:
          if (userName != '.localized') and (userName != 'Shared') and (userName != '.DS_Store'):
              userHomeFolder = usersFolder + userName
              firefoxProfileFolder    = userHomeFolder + '/Library/Application Support/Firefox/Profiles'
              safariExtensionPath     = userHomeFolder + '/Library/Safari/Extensions/{}.safariextz'.format(COMPANY_NAME0)

              RemoveFile(safariExtensionPath)
              RemoveFile(safariExtensionPath.replace(COMPANY_NAME0, COMPANY_NAME1))

              if os.path.isdir(firefoxProfileFolder):
                  firefoxProfileList =  os.listdir(firefoxProfileFolder)
                  for profileName in firefoxProfileList:
                      if profileName != '.DS_Store':
                          profileFolderPath   = os.path.join(firefoxProfileFolder, profileName)
                          aphFilePath         = profileFolderPath + '/extensions/rblaph@{}.com'.format(COMPANY_NAME0.lower())
                          if os.path.isfile(aphFilePath):
                            os.remove(aphFilePath)
    except Exception as e:
      log_error("Exception occured: " + traceback.format_exc())

def executeBashCmd(command):
    try:
        process = Popen(command, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True)
        output, error = process.communicate()
        retcode = process.poll()
        if error:
            log_error(error)
        return output, error, retcode
    except subprocess.CalledProcessError, e:
        log_error("Error executing ==" + cmd + " " + args + "==" + e.output)

def IsAVPName(name):
    for prefix in daemonPrefix:
        if name.startswith(prefix):
            return True

    return False


def IsTigerOrOlder():
    # 10.6.8
    numbers = commands.getoutput('sw_vers -productVersion').split('.')
    if not numbers or (3 > len(numbers)) or (10 != int(numbers[0])):
        return False
    return (int(numbers[1]) <= 4)

def KillDaemonsAndConsoles():
    rmDriver = os.path.isfile('/private/var/db/receipts/com.{}.avp.installer.plist'.format(COMPANY_NAME0))

    for kill in ['killall {} 2> /dev/null'.format(COMPANY_NAME0), 'killall {}Scanner 2> /dev/null'.format(COMPANY_NAME0)]:
        executeBashCmd(kill)
        executeBashCmd(kill.replace(COMPANY_NAME0, COMPANY_NAME1))

    executeBashCmd('sudo launchctl remove com.bitdefender.Daemon')
    executeBashCmd('sudo launchctl remove com.bitdefender.CoreIssues')
    executeBashCmd('sudo launchctl remove com.bitdefender.UpdDaemon')
    executeBashCmd('sudo killall -15 epagd')
    executeBashCmd('sudo killall -15 BDLDaemon')
    executeBashCmd('sudo killall -15 BDCoreIssues')
    executeBashCmd('sudo killall -15 BDUpdDaemon')
    time.sleep(10)
    executeBashCmd('sudo killall -9 epagd')
    executeBashCmd('sudo killall -9 BDLDaemon')
    executeBashCmd('sudo killall -9 BDCoreIssues')
    executeBashCmd('sudo killall -9 BDUpdDaemon')

    if rmDriver:
        for kextunload in ['kextunload -b com.Bitdefender.iokit.av']:
            executeBashCmd(kextunload)
            executeBashCmd(kextunload.replace(COMPANY_NAME0, COMPANY_NAME1))
    #   unreleased
    #executeBashCmd('kextunload -b com.bitdefender.driver.BDPRedir')


def GetUninstallLink():
    ret = True
    try:
        jobj = json.loads(open("/Library/{}/AVP/enterprise.bundle/epag.jso".format(COMPANY_NAME0)).read())
        srvaddr = jobj["conn"]["srvaddr"]
        hwid = jobj["id"]["hwid"]
        url = urlparse.urlsplit(srvaddr).scheme + "://" + urlparse.urlsplit(srvaddr).netloc + "/hydra/uninstall/61/" + hwid
        open("/tmp/uninstall-link.txt", "w+").write(url)
    except:
        try:
            os.unlink("/tmp/uninstall-link.txt")
        except OSError, e:
            if e.errno != errno.ENOENT:
                raise e
            ret = False
    return ret


def CallUninstallLink():
    ret = True
    try:
	    url = open("/tmp/uninstall-link.txt", "r").read()
    except:
	    ret = False
    try:
        fd = urllib2.urlopen(url)
    except:
        ret = False
    try:
        os.unlink("/tmp/uninstall-link.txt")
    except OSError, e:
	    ret = False
#         if e.errno != errno.ENOENT:
#             raise e
    return ret

def KillAndRemoveAntivirusForMac():
    #unload all daemons and agents
    log_info("Unload Agents & Daemons...")
    # Get the user
    fd = subprocess.Popen( [ "/bin/sh", "-c", "who | grep console | cut -d' ' -f1 | sort | uniq | head -n 1" ], stdout = subprocess.PIPE )
    ( out, err ) = fd.communicate()
    user = out.strip()
    fd = subprocess.Popen( [ "/usr/bin/id", "-u", user ], stdout = subprocess.PIPE )
    ( out, err ) = fd.communicate()
    userID = out.strip()
    
    # Stop the console as user
    executeBashCmd("sudo -u %s launchctl unload /Library/LaunchAgents/com.{}.antivirusformac.plist".format(COMPANY_NAME0.lower()) %(user))
    # Stop the enterprise console
    executeBashCmd("sudo launchctl asuser %s sudo -u %s launchctl unload /Library/LaunchAgents/com.{}.EndpointSecurityforMac.plist 2>/dev/null".format(COMPANY_NAME0.lower()) %( userID, user ))
    executeBashCmd("sudo -u %s killall -SIGKILL EndpointSecurityforMac 2>/dev/null" %( user ))
    # Stop the daemons
    executeBashCmd("sudo launchctl unload /Library/LaunchDaemons/com.{}.upgrade.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo launchctl unload /Library/LaunchDaemons/com.{}.epag.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo launchctl unload /Library/LaunchDaemons/com.{}.AuthHelperTool.plist".format(COMPANY_NAME0.lower()))

    # rm app + app folder + preferences
    log_info("Remove Files&Folders....")
    executeBashCmd("sudo rm -rf /Library/{}/AVP".format(COMPANY_NAME0))
    executeBashCmd("sudo rm -rf /Applications/Antivirus\ for\ Mac.app")
    executeBashCmd("sudo rm -rf /private/var/tmp/{}".format(COMPANY_NAME0))
    # remove the enterprise app link
    executeBashCmd("sudo rm -rf /Applications/Endpoint\ Security\ for\ Mac.app")

    executeBashCmd("sudo rm -rf /Library/Preferences/com.{}.antivirusformac.plist".format(COMPANY_NAME0.lower()))
    # Remove the enterprise preferences
    epsmacPlistPath = "/Library/Preferences/com.{}.EndpointSecurityforMac.plist".format(COMPANY_NAME0.lower())
    executeBashCmd("sudo rm -rf {}".format(epsmacPlistPath))
    for homeDir in os.listdir("/Users"):
        plistToRemove = "/Users/{}/{}".format(homeDir, epsmacPlistPath)
        executeBashCmd("sudo rm -rf {}".format(plistToRemove))

 	# Remove the enterprise preferences logger bitdefender plists
    executeBashCmd("sudo rm -rf /Library/Preferences/{}".format(COMPANY_NAME0))

    # remove launch daemons
    executeBashCmd("sudo rm -rf /Library/LaunchDaemons/com.{}.coreissues.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /Library/LaunchDaemons/com.{}.update.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /Library/LaunchDaemons/com.{}.upgrade.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /Library/LaunchDaemons/com.{}.epag.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /Library/LaunchDaemons/com.{}.bdoddaemon.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /Library/LaunchDaemons/com.{}.AuthHelperTool.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /Library/LaunchAgents/com.{}.antivirusformac.plist".format(COMPANY_NAME0.lower()))
    # Remove the Enterprise Console agent file
    executeBashCmd("sudo rm -rf /Library/LaunchAgents/com.{}.EndpointSecurityforMac.plist".format(COMPANY_NAME0.lower()))

    # kill the console
    executeBashCmd("sudo killall kill AntivirusforMac")
    # kill the Enterprise console
    executeBashCmd("sudo killall kill EndpointSecurityforMac")

    # remove installer files
    executeBashCmd("sudo rm -rf /private/var/db/receipts/com.{}.antivirusformac.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /private/var/db/receipts/com.{}.antivirusformac.bom".format(COMPANY_NAME0.lower()))

    # remove uninstaller files
    executeBashCmd("sudo rm -rf /private/var/db/receipts/com.{}.antivirusformac.uninstaller.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /private/var/db/receipts/com.{}.antivirusformac.uninstaller.bom".format(COMPANY_NAME0.lower()))

    # remove enterprise bom files
    executeBashCmd("sudo rm -rf /private/var/db/receipts/com.{}.EndpointSecurityforMac.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /private/var/db/receipts/com.{}.EndpointSecurityforMac.bom".format(COMPANY_NAME0.lower()))

    # remove enterprise caches files
    executeBashCmd("sudo rm -rf /Library/Application\ Support/Antivirus\ for\ Mac/Cache")
    executeBashCmd("sudo rm -rf /Library/Application\ Support/Antivirus\ for\ Mac/Enterprise")

def UninstallVsp():
    log_info("Uninstall Virus Scanner Plus...")
    RemoveAppByBundleID("com.{}.virusscannerplus".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo killall kill 'VirusScannerPlus'")
    executeBashCmd("sudo -u %s launchctl remove com.{}.VirusScannerHelper".format(COMPANY_NAME0.lower()) % os.getlogin())
    for item in VirusScannerPlusFiles:
        RemoveUserFileOrFolder(item)

def RemoveAppByBundleID(bundleID):
    command = "mdfind ""kMDItemCFBundleIdentifier == '%s'""" % bundleID
    out, err, retcode = executeBashCmd(command)
    for appPath in out.split("\n"):
        RemoveFileOrFolder(appPath)

def RemoveAppsByBundleID():
    for bundleID in bundleIDs:
        RemoveAppByBundleID(bundleID)

def RemoveVirusScanner():
    log_info("Uninstall Bitdefender Virus Scanner...")
    executeBashCmd("sudo killall kill '{} Virus Scanner'".format(COMPANY_NAME0))
    for item in VirusScannerFiles:
        RemoveUserFileOrFolder(item)

def get_username():
    return pwd.getpwuid( os.getuid() )[ 0 ]

def UninstallEnterprise():
    executeBashCmd("sudo launchctl unload 2> /dev/null /Library/LaunchDaemons/com.{}.epag.plist".format(COMPANY_NAME0.lower()))
    executeBashCmd("sudo rm -rf /Library/LaunchDaemons/com.{}.epag.plist".format(COMPANY_NAME0.lower()))

def UninstallKext(kext_name):
    executeBashCmd("sudo kextunload /Library/Extensions/{}.kext 2>/dev/null".format(kext_name))
    executeBashCmd("sudo rm -rf /Library/Extensions/{}.kext".format(kext_name))

def get_mounted_dmgs():
	log_info( "searching for mounted DMG images ..." )
	dmgs = []
	fd = subprocess.Popen( [ "hdiutil", "info" ], stdout = subprocess.PIPE )
	( out, err ) = fd.communicate()
	for line in out.split( "\n" ):
		m = re.match( "^image-path.*:(.*)$", str( line ).strip() )
		if m != None:
			image = str( m.group( 1 ) ).strip()
			log_info( "found '" + image + "'" )
			dmgs.append( image )
	return dmgs

#
# The file 'installer.xml' should be right next to the .dmg
#
def installer_xml_from_dmg():
	path = None
	dmgs = get_mounted_dmgs()
	if len( dmgs ) < 1:
		log_warning( "no mounted DMG-s were found" )
		return None
	for dmg in dmgs:
		m = re.match( "antivirus_for_mac.*\.dmg", os.path.basename( dmg ) )
		if m != None:
			path = os.path.join( os.path.dirname( dmg ), "installer.xml" )
			if not os.path.exists( path ):
				log_warning( "there is no 'installer.xml' next to '" + dmg + "'" )
				path = None
			else:
				break
	if path == None:
		log_warning( "cannot find our DMG or 'installer.xml'" )
		return None
	return path

def installer_xml_from_pkg( pkg ):
	path = os.path.join( os.path.dirname( pkg ), "installer.xml" )
	if not os.path.exists( path ):
		log_warning( "cannot find 'installer.xml' next to '" + pkg + "'" )
		path = None
	return path

def use_installer_xml( pkg ):
	global submit_dumps
	global submit_quarantine
	
	path = installer_xml_from_pkg( pkg ) or installer_xml_from_dmg()

	if path == None:
		log_warning( "No installer.xml ")
		return
	log_info("Have an installer.xml")
	try:
		dom = xml.dom.minidom.parse( open( path, "r" ) )
		#Keep settings (mutual auth)
		#keep_settings = 0
		nodes = dom.getElementsByTagName( "keepSettings" )
		if len( nodes ) > 0 and nodes[0].firstChild and nodes[0].firstChild.data == "1":
			log_info("Initiating keeping of madata")
			executeBashCmd("rm -r /tmp/bdtmp/ 2>/dev/null; mkdir /tmp/bdtmp")
			executeBashCmd("cp -r /Library/{}/AVP/enterprise.bundle/madata /tmp/bdtmp/".format(COMPANY_NAME0))

	except:
		log_error( "failed to parse '" + path + "'" )

def sendUninstallEvent():
    uninstallproccesfilepath = '/Library/Application Support/Antivirus for Mac/uninstall_status.json'
    senduninstalleventfilepath = '/Library/{}/AVP/enterprise.bundle/SendUninstallEvent'.format(COMPANY_NAME0)
    if os.path.isfile('/Library/Application Support/Antivirus for Mac/product_status.json'):
        f1 = open(uninstallproccesfilepath, 'wt')

        f2 = open('/tmp/bdun', 'wt')

        if os.path.isfile(senduninstalleventfilepath):      
            os.system(senduninstalleventfilepath)
        os.remove(uninstallproccesfilepath)
        os.remove('/Library/Application Support/Antivirus for Mac/product_status.json')

def removeLoggerConfigFiles():
    # Remove the enterprise preferences logger bitdefender plists
    executeBashCmd("sudo rm -rf /Library/Preferences/{}".format(COMPANY_NAME0))


class TLS1Connection( httplib.HTTPSConnection ):
    def __init__( self, host, **kwargs ):
        httplib.HTTPSConnection.__init__( self, host, **kwargs )

    def connect( self ):
        sock = socket.create_connection( ( self.host, self.port ), self.timeout, self.source_address )
        if getattr( self, '_tunnel_host', None ):
            self.sock = sock
            self._tunnel()
        self.sock = ssl.wrap_socket( sock, self.key_file, self.cert_file, ssl_version = ssl.PROTOCOL_TLSv1 )

class TLS1Handler( urllib2.HTTPSHandler ):
    def __init__( self ):
        urllib2.HTTPSHandler.__init__( self )

    def https_open( self, req ):
        return self.do_open( TLS1Connection, req )
# def RelaunchFinderToRemovePlugin():
#     for p in pwd.getpwall():
#         if p[0].startswith("_"):
#             continue
#         if p[0] == "root":
#             continue
#         if p[0] == "nobody":
#             continue
#         output, error, retcode = executeBashCmd("sudo launchctl asuser %d /usr/bin/pluginkit -m -v -i com.bitdefender.EndpointSecurityforMac.FinderIntegration" %(getpwnam(p[0]).pw_uid))
#         if "no matches" in output:
#             continue
#         executeBashCmd("sudo launchctl asuser %d /usr/bin/pluginkit -e ignore -i com.bitdefender.EndpointSecurityforMac.FinderIntegration" %(getpwnam(p[0]).pw_uid))
#         #time.sleep ( 3 ) 
#         executeBashCmd("sudo launchctl asuser %d /usr/bin/pluginkit -r /Library/Bitdefender/AVP/EndpointSecurityforMac.app/Contents/PlugIns/FinderIntegration.appex" %(getpwnam(p[0]).pw_uid))
#         #time.sleep ( 3 )
#     executeBashCmd("rm -rf /Library/Bitdefender/AVP/EndpointSecurityforMac.app/Contents/PlugIns/FinderIntegration.appex")
#     #time.sleep ( 15 )
#     #executeBashCmd("sudo /usr/bin/killall Finder")

def main():
    #
    # Force Python's urllib2 to use PROTOCOL_TLSv1 by default (SSLv23 is/should be dead)
    #
    log_info("Uninstaller started")
    urllib2.install_opener( urllib2.build_opener( TLS1Handler() ) )
		
		

    try:
        if ( len(sys.argv) > 1):
            use_installer_xml( sys.argv[1] )

         # send uninstall event
        sendUninstallEvent()
        # obtain the uninstall link
        GetUninstallLink()

       

        if os.path.isdir('/Library/{}/AVP/contentControl.bundle'.format(COMPANY_NAME0)):
            sys.path.insert(0, '/Library/{}/AVP/contentControl.bundle'.format(COMPANY_NAME0))
            from preinstallContentControl import RemoveMITMCertificate
            RemoveMITMCertificate()
        
        #remove the FinderIntegration Plugin 
        # RelaunchFinderToRemovePlugin()
        RemoveVirusScanner()
        KillAndRemoveAntivirusForMac()
        UninstallVsp()
        KillDaemonsAndConsoles()
        RemFilesAndFolders()
        UninstallEnterprise()
        RemoveAppsByBundleID()
        kext_list = ["atc", "devmac", "mdrfp", "mdredr", "mdrnet"]
        for kext in kext_list:
             UninstallKext(kext)

        # let GZ know we've been uninstalled
        CallUninstallLink()

        #remove Logger Config Files after all the deamons are killed
        removeLoggerConfigFiles()

    except Exception as e:
        log_error("Exception occured: " + traceback.format_exc())




if __name__ == "__main__":
    main()
