#!/bin/bash


#welcome to zackn9nes jamf hostname script
#if using with JSS make a policy
#put hashed username:pass in $4 base64
#put jssurl in $5, include the https:// or else
#if jamf is not on the target host it will run in native mode so ignore the above 2 things
#if not using with jamf set manuallocation immediatly here and you don't have to touch anything else
manuallocation="NY"

#jamfmode logic
jamfbinary=$(/usr/bin/which jamf)
if test -f "$jamfbinary"; then
    echo "$jamfbinary exist"
    JAMFMODE=true
else
	echo "no jamf mode"
	JAMFMODE=false
fi

#jss variables set?
if [ "$JAMFMODE" == true ]; then
	#sanity check
	if [ -z "$4" ]
	then
		echo "you forgot to fill user/pass out in jamf"
	    exit 1
	elif [ -z "$5" ]
	then
	     echo "you forgot to put jamfpro URL in jamf"
	     exit 1
	fi
fi

#jamf API subset/location 
if [ "$JAMFMODE" == true ]; then
    jssCredsHash=$4 # hash your JamfPro username:password with base64
    jssHost=$5 #put jssurl here, include the https:// or else
    #**** get the endpoints serial 
    fullSerialForAPI=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
    #**** query API for serial's city
    location=$(/usr/bin/curl -H "Accept: text/xml" -H "Authorization: Basic ${jssCredsHash}" "${jssHost}/JSSResource/computers/serialnumber/${fullSerialForAPI}/subset/location" | xmllint --format - 2>/dev/null | awk -F'>|<' '/<building>/{print $3}'|cut -f1 -d"@")
    echo "detected JSS location is" $location
elif [ "$JAMFMODE" == false ]; then
    if [ -z "$manuallocation" ]
    then
    echo "you forgot to set a manual location"
    else
    echo "setting location manually to $manuallocation"
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
elif [[ $initialhweval == *"MacBook"* ]];
then
    echo "Model: MB12 aka MB"
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
elif [ $user = "splash" ]
then
     echo "Error: user is splash user failing gracefully"
     exit 1
elif ((MNF_YEAR <= 2000 && MNF_YEAR >= 2030)); then
     echo "year is out of range just giving up on the year"
     $MNF_YEAR = ''
elif [ -z "$location" ] && [ "$JAMFMODE" == true ];
then
	echo "Error: Location is broken for JamfMode exiting with error $location"
    exit 1
elif [ -z "$model" ]
then
	echo "Error: Model is broken exiting with error"
    exit 1
fi

#do all of the things
if [ "$JAMFMODE" == true ]; then
	#do all of the things JAMF
	hostname="${location}-${model}-${MNF_YEAR}-${user}"
	echo "hostname will be: ${hostname}"
	$jamfbinary setComputerName -name "$hostname"
	$jamfbinary recon
elif [ "$JAMFMODE" == false ]; then
	#do them in a more general format
	hostname="${manuallocation}-${model}-${MNF_YEAR}-${user}"
	echo "hostname will be: ${hostname}"
	read -p 'Press [Enter] key to proceed...'
	sudo scutil --set HostName "$hostname"
	sudo scutil --set ComputerName "$hostname"
	sudo scutil --set LocalHostName "$hostname"
	dscacheutil -flushcache
	while true; do
	    read -p "Do you wish to delete this program off the disk?" yn
	    case $yn in
		[Yy]* ) rm host-name-changer.sh; break;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
	    esac
	done
fi

exit 0
