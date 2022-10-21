#!/bin/bash

#requires jo - brew install jo
#define uptime beforehand so it can be calculated within the jo command
UpTime=$(uptime | awk '{print $3}')
username="$(stat -f%Su /dev/console)"
realname="$(dscl . -read /Users/$username RealName | cut -d: -f2 | sed -e 's/^[ \t]*//' | grep -v "^$")"
boot_time_date=$( sysctl -n kern.boottime | awk -F'[^0-9]*' '{ print $2 }' | xargs date -jf "%s" "+%F %T %z" )
CPUManu="$(sysctl -n machdep.cpu.brand_string)"
#CPUName="$(sysctl -n machdep.cpu.vendor)"
CPUCore="$(sysctl -n machdep.cpu.core_count)"
#generate json data with jo
Data=$(/opt/homebrew/Cellar/jo/1.6/bin/jo \
Endpoint="`hostname`" \
UserName="$realname" \
ManagedBy="Jamf Pro" \
Model="$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')" \
Manufacturer="Apple" \
LastBoot="$boot_time_date" \
Serial="$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')" \
BiosVersion="$(system_profiler SPHardwareDataType | awk '/System Firmware Version/ {print $4}')" \
RAM="$(system_profiler SPHardwareDataType | awk '/Memory/ {print $2}')" \
OSVersion="$(sw_vers | awk '/ProductVersion/ {print $2}')" \
OSName="macOS" \
CPUManufacturer="$CPUManu" \
CPUName="$CPUName" \
CPUCores="$CPUCore" \
CPULogical="$(system_profiler SPHardwareDataType | awk '/Total Number of Cores/ {print $6}' | sed 's/(//')" \
StorageTotal="$(df -k . | awk '{print $2}' | awk 'NR!=1')" \
StorageFree="$(df -k . | awk '{print $4}' | awk 'NR!=1')")
#post to azure log analytics
curl -H "Content-Type: application/json" -d "$Data"Your workflow url using the http data collector api"
