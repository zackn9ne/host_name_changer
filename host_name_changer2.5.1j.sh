#!/bin/bash

#welcome to zackn9nes jamf hostname script
jamfbinary=$(/usr/bin/which jamf)


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



#jamf API section --------------------------------------------
jssCredsHash=$4 # hash your JamfPro username:password with base64
jssHost=$5 #put jssurl here, include the https:// or else
#**** get the endpoints serial 
fullSerialForAPI=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
#**** query API for serial's city
location=$(/usr/bin/curl -H "Accept: text/xml" -H "Authorization: Basic ${jssCredsHash}" "${jssHost}/JSSResource/computers/serialnumber/${fullSerialForAPI}/subset/location" | xmllint --format - 2>/dev/null | awk -F'>|<' '/<building>/{print $3}'|cut -f1 -d"@")
#jamf API section --------------------------------------------



#apple support curl --------------------------------------------
#get last four serial for year
YEAR=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | grep -o '....$')
echo "last four is" $YEAR
#use that (serial) for actual year
MNF_YEAR=$(curl "https://support-sp.apple.com/sp/product?cc=`echo $YEAR`" |grep -Eo '[0-9]{4}')
echo "determined year is" $MNF_YEAR
#apple support curl --------------------------------------------


#get model info locally --------------------------------------------
initialhweval=$(sysctl hw.model)
if [[ $initialhweval == *"Pro"* ]];
then
    echo "Pro detected proceeding to eval model type"
    model="MBP"
elif [[ $initialhweval == *"Air"* ]];
then
    echo "You have a macbook air, sorry to hear that"
    model="MBA"
elif [[ $initialhweval == *"MacBook"* ]];
then
    echo "You have a macbook 12"
    model="MBA"
elif [[ $initialhweval == *"iMac"* ]];
then
    echo "Desktop mac"
    model="iMac"
elif [[ $initialhweval == *"mini"* ]];
then
    echo "Desktop mac"
    model="Mini"
elif [ -z "$initialhweval" ];
then
    echo "computer unknown"
exit 1

    echo $model
fi
#get model info locally --------------------------------------------

#check user locally --------------------------------------------
user=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
echo "detected location is" $location
echo "detected user is:" $user
#check user locally --------------------------------------------

#sanitize user
user=$(echo $user | sed 's/[^a-zA-Z0-9]//g')

#killswitch
if [ -z "$user" ]
then
	echo "user is null exiting with error"
    exit 1
elif [ $user = "root" ]
then
     echo "user is root user failing gracefully"
     exit 1
elif [ $user = "splash" ]
then
     echo "user is splash user failing gracefully"
     exit 1
elif ((MNF_YEAR <= 2000 && MNF_YEAR >= 2030)); then
     echo "year is out of range just giving up on the year"
     $MNF_YEAR = ''
elif [ -z "$location" ]
then
	echo "Location is broken exiting with error $location"
    exit 1
elif [ -z "$model" ]
then
	echo "Model is broken exiting with error"
    exit 1

else
    echo "proceeding"
fi


#do all of the things
hostname="${location}-${model}-${MNF_YEAR}-${user}"
echo "computer calculated as " $hostname

$jamfbinary setComputerName -name "$hostname"
$jamfbinary recon

exit 0
