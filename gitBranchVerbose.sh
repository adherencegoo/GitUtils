#!/bin/bash
# Usage: no input

declare -r QUOTE="qwerty" #read only

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

#========================================================
#TODO: tmp solution for commit containing apostrophe
formatString="isHead=%(HEAD) branchName=%(refname:short) sha=%(objectname:short) commitTitle=%(contents:subject) upstream=%(upstream) push=%(push)"
# formatString="isHead=${QUOTE}%(HEAD)${QUOTE} branchName=${QUOTE}%(refname:short)${QUOTE} sha=${QUOTE}%(objectname:short)${QUOTE} commitTitle=${QUOTE}%(contents:subject)${QUOTE} upstream=${QUOTE}%(upstream)${QUOTE} push=${QUOTE}%(push)${QUOTE}"

#========================================================
# branchConfigs=`git config --get-regex ^branch.*.*$`;
# branchBasics=`git for-each-ref --format="$formatString" refs/heads`;
# echo "branchConfigs:"${branchConfigs[@]}
# echo "branchConfigs:"${branchConfigs}
# echo "branchConfigs:"${#branchConfigs[@]}
# echo
# echo "branchBasics:"${branchBasics[@]}
# echo "branchBasics:"${branchBasics}
# echo "branchBasics:"${#branchBasics[@]}
# echo
# exit

#========================================================
git for-each-ref --shell --format="$formatString" refs/heads | \
while read entry; do #it must be "entry"
	echo -n $resetText;
	printf "=%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
	
	#escape characters:
	entry=${entry//'"'/'\"'} #" --> \"
	entry=${entry//"'''"/${QUOTE}} #''' --> ${QUOTE}
	entry=${entry//"'"/'"'} #' --> "
	entry=${entry//${QUOTE}/"'"} #${QUOTE} --> '
	
	set -f;#disable globbing
	eval "$entry"
	set +f;#enable globbing
	
	#handle is head or not====================================================
	if [ "$isHead" == "*" ]; then
		branchNameColor=$greenText$invertEnable;
	else
		branchNameColor=$magentaText;
	fi
	headerColor=$resetText;
	headerAbbr=${branchName:0:1};#extrieve the first character
	headerAbbr=${headerAbbr^^};#to upper case

	
	#start to echo this branch==============================================
	#one line vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	echo -e -n $headerColor"$headerAbbr ";
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
	
	#tmp solution to break lines with specified token " - "; bug: successive tokens will produce unwanted result
	commitTitle=${commitTitle//' - '/"\n\t                 - "}
	echo -e $headerColor"\tCommit: $sha "$cyanText"$commitTitle";	
	
	[[ ! -z "${upstream// }" ]] && echo -e $headerColor"\tupstream: "$redText"$upstream";
	[[ ! -z "${push// }" ]] && echo -e $headerColor"\tpush: "$redText"$push";
		
	description=`git config branch.$branchName.description`;
	if [[ ! -z "${description// }" ]]; then
		description=${description//' - '/"\n\t\t - "} #why can't I add more spaces???
		echo -e $headerColor"\tDescription: "$yellowText$description;
	fi
done
