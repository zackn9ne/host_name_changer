# Zackn9nez Host Name Changer 2.5.1
This changes your macOS hostname based on machine year, and last user

# Run without JAMF
- basically download and run, depending on how you run you may need `sudo`
- script will ask you promt for LOCATION
- when script completes it asks you if you want to erase the proggie off of the disk, that's up to you
- shortcut to downloading and running in case you are lazy:

![stuff](https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/socialmedia/apple/237/white-down-pointing-backhand-index_1f447.png)

`curl https://raw.githubusercontent.com/zackn9ne/host_name_changer/master/host_name_changer2.5.1j.sh > host-name-changer.sh && sh host-name-changer.sh`

# Run on JAMF (JSS) 
- put this in your scripts
- make a policy and call this script
- hash your JamfPro username:password with base64 and put it in $4 of the policy
- put JSSURL in $5 of the policy, include the https:// or else
- no need to recon after, script recons after all changes made, it is an inventory script after all

