#!/bin/bash

printf "\n=========================================================\n\n"
printf "            ~~~ RESTORE ANDROID PACKAGES ~~~\n\n"
printf "=========================================================\n\n"

# The following script will restore apps 
# from a TWRP backup to an android phone.
# Modified adbd service or Magisk must be used.

# 1. Extract all the data volumes in the TWRP backup
	# cat data.*.win??? | tar xvfi -
# 2. Turn the bash script into an executable 
	# chmod +x load_packages.sh
# 3. Run script
	# ./load_packages.sh

# The following resources were used in the creation of this script.
# https://www.semipol.de/2016/07/30/android-restoring-apps-from-twrp-backup.html
# https://itsfoss.com/fix-error-insufficient-permissions-device/


##                         ##
#### BEGIN CONFIGURATION ####
##                         ##

# TWRP extract location for data/data/
localpackages='data/data/'
# Android temp destination
temppackages='/sdcard/tmp/'
# Android final destination
remotepackages='/data/data/'

# filename of packages in data/data/ to restore (one by line and between double quotes)
declare -a packages=(
"io.getdelta.android"
"ca.mogo.mobile"
"au.com.shiftyjelly.pocketcasts"
"com.valvesoftware.android.steam.community"
"com.ubercab"
"de.stocard.stocard"
"com.wealthsimple"
"com.calm.android"
"com.coinomi.wallet"
"com.aspiro.tidal"
"com.appgenix.bizcal"
"com.americanexpress.android.acctsvcs.ca"
"com.amazon.venezia"
)

##                         ##
#### END CONFIGURATION ######
##                         ##


printf "=========================================================\n\n"
printf "Executing 'adb root' command:\n\n"
adb root
printf "\n"
id=$(adb shell id -u)
uid=$id
if [[ $id != "0" ]] ; then
	id=$(adb shell su -c "id -u")
	if [ -z "$id" ] ; then
		id=$uid
	fi
fi
printf "\n[INFO] User ID of adb is '%s' (must be '0').\n\n" "$id"
if [[ $id != "0" ]] ; then
	printf "[ERROR] Didn't get root permissions! Can't restore.\n\n"
	printf "[INFO] You can chose one of this two ways to be able to restore:\n\n- Install a modified adbd\n- Install Magisk and allow root for 'Shell' package\n\n"
	printf "=========================================================\n\n"
	exit
else
	printf "=========================================================\n\n"
fi

# get total number of packages to restore
len=$(printf '%s\n' "${packages[@]}" | wc -w)

# init counters
# n = number of the actual package to be restored
# g = number of app data successfully restored
n=0
g=0

for package in ${packages[*]}
do
	n=$((n + 1))
	printf "=========================================================\n\n"
	printf "|***| Starting process for \"%s\" package (%s of %s)\n\n" "$package" "$n" "$len"
	if [ ! -d "$localpackages$package" ] ; then
		printf "[WARN] Can't find this filename of package (%s).\n\n" "$localpackages$package"
		continue
	fi
	printf "[***] Checking device...\n"
	userid=$(adb shell dumpsys package "$package" | grep userId | cut -d '=' -f2-)
	if [[ ! $userid =~ ^[0-9]+$ ]] ; then
		userid=$(adb shell su -c "stat -c %u '$remotepackages$package'")
	fi
	if [[ $userid =~ ^[0-9]+$ ]] ; then
		printf "\n[INFO] User ID of this app is '%s'.\n\n" "$userid"
		printf "[1/5] Pushing package to temp dir...\n"
		adb push "$localpackages$package" "$temppackages$package"
		printf "[2/5] Restoring package...\n"
		adb shell su -c "cp -r '$temppackages$package' '$remotepackages'"
		printf "[3/5] Correcting package...\n"
		adb shell su -c "chown -R $userid:$userid '$remotepackages$package'"
		adb shell su -c "restorecon -R '$remotepackages$package'"
		printf "[4/5] Cleaning temp dir...\n"
		adb shell su -c "rm -rf '$temppackages$package'"
		printf "[5/5] Done!\n\n"
		g=$((g + 1))
		sleep 1
	else
		printf "\n[WARN] Can't read user ID info of this app. Can't restore.\n"
		printf "[INFO] App must be installed on your device to be able to restore package.\n\n"
	fi
done

printf "=========================================================\n\n"
printf "      SUMMARY: %s / %s SUCCESSFULLY RESTORED\n\n" "$g" "$len"
printf "=========================================================\n\n"
