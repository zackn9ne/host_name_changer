#!/bin/bash


#welcome to zackn9nes jamf hostname script
#if using with JSS make a policy
#put hashed username:pass in $4 base64
#put jssurl in $5, include the https:// or else
#if jamf is not on the target host it will run in native mode so ignore the above 2 things
#if not using with jamf set MANUALLOCATION prompts you on readline
MANUALLOCATION="NY"
#jamfmode logic
jamfbinary=$(/usr/bin/which jamf)
if test -f "$jamfbinary"; then
    echo "$jamfbinary exists you should use the JAMF script, proceeding anyway"
fi



#curl apples machine db against last 4 of serial
#get last four serial for year
lastFourSerialForAPPL=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | grep -o '....$')
echo "last four is" $lastFourSerialForAPPL
#use that (serial) for actual year
MNF_YEAR=$(curl "https://support-sp.apple.com/sp/product?cc=`echo $lastFourSerialForAPPL`" |grep -Eo '[0-9]{4}')
echo "determined year is" $MNF_YEAR

#get machines info locally
initialhweval=$(sysctl hw.model)
if [[ $initialhweval == *"Pro"* ]];
then
    echo "Model: MBP"
    model="MBP"
elif [[ $initialhweval == *"Air"* ]];
then
    echo "Model: MBA"
    model="MBA"
elif [[ $initialhweval == *"MacBook8"* ]];
then
    echo "Model: MB12"
    model="MB"
elif [[ $initialhweval == *"MacBook9"* ]];
then
    echo "Model: MB12"
    model="MB"
elif [[ $initialhweval == *"MacBook10"* ]];
then
    echo "Model: MB12"
    model="MB"
elif [[ $initialhweval == *"iMac"* ]];
then
    echo "Model: iMac"
    model="iMac"
elif [[ $initialhweval == *"mini"* ]];
then
    echo "Model: mini"
    model="Mini"
elif [ -z "$initialhweval" ];
then
    echo "computer unknown"
exit 1

    echo "Found a ${model}"
fi

#check user locally
user=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
echo "detected user is:" $user

#sanitize user
user=$(echo $user | sed 's/[^a-zA-Z0-9]//g')

#killswitch Error:
if [ -z "$user" ]
then
	echo "Error: user is null exiting with error"
    exit 1
elif [ $user = "root" ]
then
     echo "Error: user is root user failing gracefully"
     exit 1
elif (($MNF_YEAR <= 2000 && $MNF_YEAR >= 2030)); then
     echo "year is out of range just giving up on the year"
     $MNF_YEAR = ''
elif [ -z "$model" ]
then
	echo "Error: Model is broken exiting with error"
    exit 1
fi

#do all of the things
	#do them in a more general format
	hostname="${MANUALLOCATION}-${model}-${MNF_YEAR}-${user}"
	echo "hostname will be: ${hostname}"
	sudo scutil --set HostName "$hostname"
	sudo scutil --set ComputerName "$hostname"
	sudo scutil --set LocalHostName "$hostname"
	dscacheutil -flushcache
 

exit 0
