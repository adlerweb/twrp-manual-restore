#!/bin/bash

printf "\n=========================================================\n\n"
printf "            ~~~ RESTORE ANDROID PACKAGES ~~~\n\n"
printf "=========================================================\n\n"

# The following script will restore apps 
# from a TWRP backup to an android phone.
# Root adb access or Magisk must be available.

# 1. Extract all the data volumes in the TWRP backup
	# cat data.*.win??? | tar xvfi -
# 2. Turn the bash script into an executable 
	# chmod +x load_packages.sh
# 3. Run script
	# ./load_packages.sh

# The following resources were used in the creation of this script.
# https://www.semipol.de/2016/07/30/android-restoring-apps-from-twrp-backup.html
# https://itsfoss.com/fix-error-insufficient-permissions-device/

#                           #
##                         ##
#### BEGIN CONFIGURATION ####
##                         ##
#                           #

# TWRP extract location for data/data/
localpackages='data/data/'
# Android temp destination (Magisk)
temppackages='/sdcard/tmp/'
# Android delivery destination
remotepackages='/data/data/'

# name of packages in data/data/ to restore (one by line and between double quotes)
declare -a packages=(
"change.these.names"
"com.first.app"
"com.second.app"
"com.third.app"
"com.more.apps"
)

#                           #
##                         ##
####  END CONFIGURATION #####
##                         ##
#                           #

printf "=========================================================\n\n"
printf "Executing 'adb root' command:\n\n"
adb root
printf "\n"
# c = adb command to use
c="adb shell"
id=$($c id -u)
if [[ $id != "0" ]] ; then
	printf "[INFO] 'adb root' command failed. Trying with Magisk (if installed).\n\n"
	c="$c su -c"
	id=$($c id -u)
	if [[ $id != "0" ]] ; then
		printf "\n[ERROR] Didn't get root permissions! Can't restore.\n\n"
		printf "[INFO] You can chose one of the following two ways to be able to restore:\n\n"
		printf " - Install a modded adbd version on your device\n"
		printf " - Install 'Stable' Magisk version and allow root access for \"Shell\" package\n\n"
		printf "=========================================================\n\n"
		exit
	fi
fi
printf "[INFO] Successfully got root permissions! Continue...\n\n"
printf "=========================================================\n\n"

# get total number of packages to restore
len=$(printf '%s\n' "${packages[@]}" | wc -w)

# init counters
# n = number of the actual package to be restored
# g = number of app data successfully restored
n=0
g=0

# init list of not restored packages
l=()

for package in ${packages[*]}
do
	n=$((n + 1))
	printf "=========================================================\n\n"
	printf "|***| Starting process for \"%s\" package (%s of %s)\n\n" "$package" "$n" "$len"
	if [ ! -d "$localpackages$package" ] ; then
		printf "[WARN] Can't find data directory for (%s).\n\n" "$localpackages$package"
		continue
	fi
	# remove 'lib' symbolic link in root of package if exist
	rm -f "$localpackages$package/lib"
	printf "[***] Checking device...\n\n"
	userid=$($c dumpsys package "$package" | grep userId | cut -d '=' -f2-)
	if [[ ! $userid =~ ^[0-9]+$ ]] ; then
		printf "[0/5] Installing missing application...\n"
		apkpath=$(find . -maxdepth 4 -type d -print | grep "$package" | head -n1)
		if [ ! -f "$apkpath/base.apk" ] ; then
			printf "[WARN] Application is not installed and apk not found for (%s).\n\n" "$package"
			continue
		fi
		adb install -r "$apkpath/base.apk"
	fi

	userid=$($c dumpsys package "$package" | grep userId | cut -d '=' -f2-)
	if [[ ! $userid =~ ^[0-9]+$ ]] ; then
		userid=$($c stat -c %u "$remotepackages$package")
	fi

	if [[ $userid =~ ^[0-9]+$ ]] ; then
		#printf "[INFO] User ID of this app is '%s'.\n\n" "$userid"
		printf "[1/5] Pushing package to temp dir...\n"
		adb push "$localpackages$package" "$temppackages$package"
		printf "[2/5] Restoring package...\n"
		$c cp -r "$temppackages$package" "$remotepackages"
		printf "[3/5] Correcting package...\n"
		$c chown -R "$userid":"$userid" "$remotepackages$package"
		$c restorecon -R "$remotepackages$package"
		printf "[4/5] Cleaning temp dir...\n"
		$c rm -rf "$temppackages$package"
		printf "[5/5] Done!\n\n"
		g=$((g + 1))
		sleep 1
	else
		l+=("$package")
		printf "[WARN] Can't read user ID info of this app. Can't restore.\n"
		printf "[INFO] App must be installed on your device to be able to restore package.\n\n"
	fi
done

