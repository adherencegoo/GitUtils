#!/bin/bash
resetText=`tput sgr0`
redText=`tput setaf 1`
greenText=`tput setaf 2`
yellowText=`tput setaf 3`
magentaText=`tput setaf 5`
cyanText=`tput setaf 6`

resetBg="\e[49m"
whiteBg=`tput setab 7`;

invertEnable="\e[7m";
invertDisable="\e[27m"

#TODO: tmp solution for commit containing apostrophe
formatString="isHead=%(HEAD) branchName=%(refname:short) sha=%(objectname:short) commitTitle=\"%(contents:subject)\" upstream=%(upstream) push=%(push)"
git for-each-ref --shell --format="$formatString" refs/heads | \
while read entry; do #it must be "entry"
	set -f;#disable globbing
	eval "$entry"
	set +f;#enable globbing
	
	if [ "$isHead" == "*" ]; then
		branchNameColor=$greenText$invertEnable;
	else
		branchNameColor=$magentaText;
		[[ "$branchName" == TT* ]] && isHead="T";
		[[ "$branchName" == dev* ]] && isHead="D";
	fi
	headerColor=$resetText;
	echo $resetText"-----------------------------------------------------------------------------------------------------------------------------------------------------------------";
	
	echo -e -n $headerColor"$isHead ";
	echo -e  $branchNameColor"$branchName "$invertDisable;
	echo -e $headerColor"\tCommit: $sha "$cyanText"$commitTitle";	
	
	[[ ! -z "${upstream// }" ]] && echo -e $headerColor"\tupstream: "$redText"$upstream";
	[[ ! -z "${push// }" ]] && echo -e $headerColor"\tpush: "$redText"$push";
		
	description=`git config branch.$branchName.description`;
	[[ ! -z "${description// }" ]] && echo -e $headerColor"\tDescription: "$yellowText"$description";
done

unset isHead;
unset branchName;
unset sha;
unset commitTitle;
unset description;
unset remote;
unset merge;
unset headerColor;
