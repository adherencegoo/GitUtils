#!/bin/bash
# Usage: no input

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
	
	#handle is head or not====================================================
	if [ "$isHead" == "*" ]; then
		branchNameColor=$greenText$invertEnable;
	else
		branchNameColor=$magentaText;
		[[ "$branchName" == TT* ]] && isHead="T";
		[[ "$branchName" == dev* ]] && isHead="D";
	fi
	headerColor=$resetText;
	echo -n $resetText;
	printf "=%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
	
	#start to echo this branch==============================================
	#one line vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	echo -e -n $headerColor"$isHead ";
	echo -e -n $branchNameColor"$branchName "$invertDisable;
	rank=$((`git config branch.$branchName.rank`));
	if [[ $rank =~ ^[0-9]+$ ]] && [[ $rank -gt 0 ]]; then
		# former regex: positive integer or zero
		printf "$redText\t%3d) " $rank;
		# \xE2\x98\x85 is UTF-8 form of unicode ★
		printf '\xE2\x98\x85 %.0s' `eval echo {1..$rank}`
	fi
	echo ;
	#one line ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	
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
