#!/bin/bash

# The following script will restore apps 
# from a TWRP backup to an android phone.
# Root adb access must be available.

# 1. Extract all the data volumes in the TWRP backup
	# tar -xvf data.ext4.win000
	# tar -xvf data.ext4.win001 etc.
# 2. Turn the bash script into an executable 
	# chmod +x restore_android_packages.sh
# 3. Run script
	# ./restore_android_packages.

# The following resources were used in the creation of this script.
# https://www.semipol.de/2016/07/30/android-restoring-apps-from-twrp-backup.html
# https://itsfoss.com/fix-error-insufficient-permissions-device/

# TWRP extract location for data/data/
localpackages='data/data/'
# Android temp destination
temppackages='/data/tmp/'
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
# Get total number of packages to restore
len=${#packages[@]}

printf "=========================================================\n"
printf "Starting ADB as root\n"
adb root
printf "=========================================================\n"

# Init counters
# n = Number of actual package to restore
# g = Number of app data successfully restored
n=0
g=0

for package in ${packages[*]}
do
	n=$((n + 1))
	printf "=========================================================\n\n"
	printf "|***| Starting process for \"%s\" package (%s of %s)\n\n" "$package" "$n" "$len"
	printf "[1/4] Checking device...\n"
	userid=$(adb shell su -c "dumpsys package $package | grep userId | cut -d '=' -f2-")
	if [[ $userid =~ ^[0-9]+$ ]] ; then
		printf "[INFO] User ID is %s\n" "$userid"
		printf "[2/4] Restoring data...\n"
		adb push "$localpackages$package" "$temppackages$package"
		adb shell su -c "cp -r $temppackages$package $remotepackages"
		adb shell su -c "chown -R $userid:$userid $remotepackages$package"
		adb shell su -c "restorecon -Rv $remotepackages$package"
		g=$((g + 1))
	else
		printf "[2/4] ERROR: App not found/installed! Can't restore...\n"
	fi	
	printf "[3/4] Cleaning...\n"
	adb shell rm -rf "$temppackages$package"
	printf "[4/4] Done!\n\n"
	sleep 1
done

printf "=========================================================\n"
printf "      SUMMARY: %s / %s SUCCESSFULLY RESTORED\n" "$g" "$len"
printf "=========================================================\n"
