#!/bin/bash
#Usage:
#	1st argument: local path of monkey_logs (excluding "monkey_logs")
# cp ~/.ssh/id_rsa from server and put in any path, and set rsaPath to that path

#======================================================================
# User-defined constants
declare -r remoteFolder="owen";
declare -r remoteScript="CollectData_asusgallery"
declare -r rsaPath="C:\Users\Owen_Chen\.ssh\id_rsa_amax181" #locate your key copied from server
declare -r isMobaXtem=0; #0: false, 1:true

#======================================================================
#======================================================================
#======================================================================
monkeyFolder="monkey_logs";
if [[ -z $1 ]]; then
	localRootPath="./";
else
	localRootPath="$1/";
fi
localMonkeyPath=${localRootPath}${monkeyFolder}

needAdbPull=1;
if [ -d "$localMonkeyPath" ]; then #folder exists
	echo -n "Repull $monkeyFolder from devices to $localMonkeyPath (y/N):";
	read action;
	[[ $action != "y" ]] && needAdbPull=0;
	unset action;
fi

if [[ $needAdbPull -eq 1 ]]; then 
	if [[ $isMobaXtem -eq 1 ]]; then
		#the path is for adb in MobaXterm
		mobaAdbPath=/drives/c/Users/$(whoami)/AppData/Local/Android/sdk/platform-tools;
		[[ ! -d $mobaAdbPath ]] && echo "[Error] Wrong path for adb in MobaXterm: [$mobaAdbPath]" && exit;
		export PATH=${PATH}:${mobaAdbPath};
		unset mobaAdbPath;
	fi

	if [ -d "$localMonkeyPath" ]; then #folder exists
		echo "Removing existing folder... [$localMonkeyPath]"
		rm -r $localMonkeyPath
	fi

	echo "adb root"
	adb root
	echo "adb remount"
	adb remount
	
	adbPullLogFile="tmpLog-adbPull.txt";
	deviceMonkeyPath="//mnt/sdcard/$monkeyFolder"
	echo "adb pull $deviceMonkeyPath $localMonkeyPath"
	adb pull $deviceMonkeyPath $localMonkeyPath > $adbPullLogFile
	unset deviceMonkeyPath;
fi
unset needAdbPull;

if [ -d "$localMonkeyPath" ]; then #folder exists
	rm $adbPullLogFile;
	unset adbPullLogFile;

	SERVERIP="10.78.21.181"
	USER="amax"
	remoteRootPath="/home/amax/${remoteFolder}"
	[[ ! -z $rsaPath ]] && [[ $rsaPath != "" ]] && rsaArgument=" -i $rsaPath ";
	
	echo "--Make $remoteRootPath if not present"
	ssh $rsaArgument ${USER}@${SERVERIP} "[[ ! -d $remoteRootPath ]] && mkdir $remoteRootPath";
	
	echo "--Remove remote $remoteRootPath/$monkeyFolder if present"
	ssh $rsaArgument ${USER}@${SERVERIP} "cd $remoteRootPath; [[ -d $monkeyFolder ]] && rm -rf ${monkeyFolder}; ";

	echo "--Copy Monkey logs to ${USER}@${SERVERIP}:${remoteRootPath}"
	scp $rsaArgument -r ${localMonkeyPath} ${USER}@${SERVERIP}:${remoteRootPath}

	echo "--Collect data from Monkey logs"
	ssh $rsaArgument ${USER}@${SERVERIP} "export PATH=\${PATH}:/home/amax/bin/; cd ${remoteRootPath}; ${remoteScript} ${monkeyFolder}"

	echo "--Copy result data to local"
	scp $rsaArgument -r ${USER}@${SERVERIP}:${remoteRootPath}/${monkeyFolder} $localRootPath
else
	echo "[Error] $monkeyFolder doesn't exist";
fi

#echo "--Rename"
#mv $monkeyFolder $outputdirname
#open Script_Memory_Profiling_V0.6.4_3.xls
