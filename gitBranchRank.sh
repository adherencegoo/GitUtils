#!/bin/bash
# Usage:
	# $rankVal:
		# not set: get value
		# 0: unset
		# 1/+1/-1: set to 1/1/-1
		# ++1/--1: inc/dec by 1
	# $branchName:
		# use HEAD by default

declare -r resetText=`tput sgr0`;
declare -r redText=`tput setaf 1`;
declare -r ACTION_SHOW=0;
declare -r ACTION_UNSET=1;
declare -r ACTION_SET=2;
declare -r ACTION_ADJUST=3;
#handle inputs==============================================
currentAction=$ACTION_SHOW;
for arg in $@; do 
	if [[ $arg -eq 0 ]]; then
		currentAction=$ACTION_UNSET;
	elif [[ $arg =~ ^[+-]?[1-9][0-9]*$ ]]; then #1 or +1 or -1
		currentAction=$ACTION_SET;
		rankVal=$(( $arg ));#transform into numerical value
	elif ([[ ${arg:0:2} == "++" ]] || [[ ${arg:0:2} == "--" ]]) && [[ ${arg:2} =~ ^[1-9][0-9]*$ ]]; then #++1 or --1
		#NOTE: pattern ^(?:--|[+]{2})[1-9][0-9]*$ passed on online website, but not work in bash ...
		currentAction=$ACTION_ADJUST;
		rankVal=$(( ${arg:1} ));#remove first character (or, --1 is treated as 1), and transform into numerical value
	else
		branchName=$arg;
	fi
done

#if branchName(space removed) is not specified, use HEAD
[[ -z ${branchName// } ]] && branchName=`git rev-parse --abbrev-ref HEAD`;
#TODO: if branchName is set but not valid, treat it as regex

#debug:
# echo currentAction: $currentAction
# echo rankVal: $rankVal
# echo branchName: $branchName

case $currentAction in
	$ACTION_SHOW ) #------------------------------------------------------------------------
		echo `git config branch.$branchName.rank`;
		;;
	$ACTION_UNSET ) #------------------------------------------------------------------------
		git config --unset branch.$branchName.rank
		echo "Unset rank of $branchName";

		#remove section if it's empty after unsetting this setting
		sectionContent=`git config --get-regex "^branch.$branchName.*"`;
		if [[ -z ${sectionContent// } ]]; then
			git config --remove-section branch.$branchName
			echo "Remove empty section: branch.$branchName";
		fi
		;;
	$ACTION_SET ) #------------------------------------------------------------------------
		git config branch.$branchName.rank $rankVal;
		echo "Rank of $branchName: $rankVal";
		;;
	$ACTION_ADJUST ) #------------------------------------------------------------------------
		origRank=`git config branch.$branchName.rank`;
		newRank=$(( $rankVal + $origRank ));
		if [[ $newRank -eq 0 ]]; then
			eval $(basename $0) $branchName 0; #recursive call
		else
			git config branch.$branchName.rank $newRank;
			echo "Rank of $branchName: $newRank";
		fi
		;;
	* ) #------------------------------------------------------------------------
		echo -e $redText"Unexpected action:"$currentAction;
		;;
esac
