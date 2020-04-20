#!/bin/bash

#welcome to zackn9nes jamf hostname script
#do smartgroups to parse location since we don't want API calls in scripts for SEC reasons

#if not using with jamf set LOCATION here
#if using JAMF set LOCATION in $4
LOCATION="NY"

#jamfmode logic
JAMFBINARY=$(/usr/bin/which jamf)
if test -f "$JAMFBINARY"; then
    JAMFMODE=true
    echo "$JAMFBINARY exists looking for location var in $4"
    LOCATION="$4"
fi

#curl apples machine db against last 4 of serial
#get last four serial for year
lastFourSerialForAPPL=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | grep -o '....$')
echo "last four is" $lastFourSerialForAPPL
#use that (serial) for actual year
MNF_YEAR=$(curl "https://support-sp.apple.com/sp/product?cc=$(echo $lastFourSerialForAPPL)" | grep -Eo '[0-9]{4}')
echo "determined year is" $MNF_YEAR

#get machines info locally
initialhweval=$(sysctl hw.model)
if [[ $initialhweval == *"Pro"* ]]; then
    echo "Model: MBP"
    MODEL="MBP"
elif [[ $initialhweval == *"Air"* ]]; then
    echo "Model: MBA"
    MODEL="MBA"
elif [[ $initialhweval == *"MacBook8"* ]]; then
    echo "Model: MB12"
    MODEL="MB"
elif [[ $initialhweval == *"MacBook9"* ]]; then
    echo "Model: MB12"
    MODEL="MB"
elif [[ $initialhweval == *"MacBook10"* ]]; then
    echo "Model: MB12"
    MODEL="MB"
elif [[ $initialhweval == *"iMac"* ]]; then
    echo "Model: iMac"
    MODEL="iMac"
elif [[ $initialhweval == *"mini"* ]]; then
    echo "Model: mini"
    MODEL="Mini"
elif [ -z "$initialhweval" ]; then
    echo "computer unknown"
    exit 1
    echo "Found a ${MODEL}"
fi

#check user locally
USER=$(scutil <<<"show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}')
echo "detected user is:" $USER

#sanitize user
USER=$(echo $USER | sed 's/[^a-zA-Z0-9]//g')

#killswitch conditions

if [ -z "$USER" ]; then
    echo "Error: user is null exiting with error"
    exit 1
elif [ $USER = "root" ]; then
    echo "Error: user is root user failing gracefully"
    exit 1
elif (($MNF_YEAR <= 2000)); then
    echo "year is too low"
    #get a random number generator ready once per script run should be fine
    random=$(echo "$((1000 + RANDOM % 9000))")
    $MNF_YEAR=$random

elif (($MNF_YEAR >= 2040)); then
    echo "year is too high"
    #get a random number generator ready once per script run should be fine
    random=$(echo "$((1000 + RANDOM % 9000))")
    $MNF_YEAR=$random
elif [ -z "$MODEL" ]; then
    echo "Error: Model is broken exiting with error"
    exit 1
fi

#payload
HOSTNAME="${LOCATION}-${MODEL}-${MNF_YEAR}-${USER}"

#do all the things logic
if [ "$JAMFMODE" == true ]; then
    #do all of the things with $JAMFBINARY
    echo "hostname will be: ${HOSTNAME}"
    $JAMFBINARY setComputerName -name "$HOSTNAME"
    $JAMFBINARY recon
elif [ "$JAMFMODE" != true ]; then
    #do all of the things in a general format
    echo "hostname will be: ${HOSTNAME}"
    sudo scutil --set HostName "$HOSTNAME"
    sudo scutil --set ComputerName "$HOSTNAME"
    sudo scutil --set LocalHostName "$HOSTNAME"
    dscacheutil -flushcache
fi
exit 0
