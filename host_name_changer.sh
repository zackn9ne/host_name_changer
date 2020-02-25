#!/bin/bash

#welcome to zackn9nes jamf hostname script
jamfbinary=$(/usr/bin/which jamf)
location=$4 #for jamf operator input #required
model=$5 #for jamf operator input #not required


#*** testing
location="NY"

#get (serial for) year
YEAR=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | grep -o '....$')
echo "last four is" $YEAR
#use that (serial) for actual year
MNF_YEAR=$(curl "https://support-sp.apple.com/sp/product?cc=`echo $YEAR`" |grep -Eo '[0-9]{4}')
echo "determined year is" $MNF_YEAR

#get model
initialhweval=$(sysctl hw.model)
if [[ $initialhweval == *"Pro"* ]];
then
    echo "Pro detected proceeding to eval model type"
    model="MBP"
elif [[ $initialhweval == *"Air"* ]];
then
    echo "You have a macbook air, sorry to hear that"
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

#check user 
user=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
echo "detected location is" $location
echo "detected user is:" $user

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
	echo "Location is broken exiting with error either set variable manually or put in $4 of jamf pro"
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
echo $hostname


#***testing!! 
#read -n 1 -s -r -p "Press any key to continue"
$jamfbinary setComputerName -name "$hostname"
$jamfbinary recon


