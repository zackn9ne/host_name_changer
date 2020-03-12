# Zackn9nez Host Name Changer 2.5.1
This changes your macOS hostname based on machine year, and last user

# If not on JAMF
curl https://raw.githubusercontent.com/zackn9ne/host_name_changer/master/host_name_changer2.5.1j.sh > host-name-changer.sh

# If on JAMF (JSS) 
- put this in your scripts
- make a policy and call this script
- no need to recon after, script recons after all changes made, it is an inventory script after all
- hash your JamfPro username:password with base64 and put it in $4 of the policy
- put jssurl in $5 of the policy, include the https:// or else
