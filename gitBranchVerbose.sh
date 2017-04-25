#!/bin/bash

#read only constants =====================================
declare -r QUOTE="qwerty"
declare -r TYPE_UNKNOWN=0;
declare -r TYPE_DIVERGENT=1;
declare -r TYPE_CONVERGENT=2;
declare -r TYPE_EXACT=3;

declare -r resetText=`tput sgr0`
declare -r redText=`tput setaf 1`
declare -r greenText=`tput setaf 2`
declare -r yellowText=`tput setaf 3`
declare -r magentaText=`tput setaf 5`
declare -r cyanText=`tput setaf 6`

declare -r resetBg="\e[49m"
declare -r whiteBg=`tput setab 7`;

declare -r dimEnable="\e[2m";
declare -r dimDisable="\e[22m";
declare -r invertEnable="\e[7m";
declare -r invertDisable="\e[27m"

#default values====================================
#about branches
declare -r boolBranchesDivergentOnlyKeys=("-dv" "--divergent-only"); boolBranchesDivergentOnly=0;
declare -r boolBranchesWithUpstreamOnlyKeys=("-u" "--upstream-only"); boolBranchesWithUpstreamOnly=0;

#about info
declare -r boolInfoHeaderKeys=("-h" "--header"); boolInfoHeader=1;
declare -r strInfoHighlightedBranchKeys=("-hl" "--highlight"); unset strInfoHighlightedBranch;
declare -r boolInfoRemoteKeys=("-r" "--remote"); boolInfoRemote=1;
declare -r boolInfoCommitKeys=("-c" "--commit"); boolInfoCommit=1;
declare -r intInfoCommitLinesKeys=("-cl" "--commit-lines"); unset intInfoCommitLines;
declare -r boolInfoDescriptionKeys=("-de" "--description"); boolInfoDescription=1;
declare -r boolInfoRankKeys=("-k" "--rank"); boolInfoRank=1;

#others
declare -r boolInteractiveKeys=("-i" "--interactive"); boolInteractive=0;
declare -r boolSeparatorKeys=("-s" "--separator"); boolSeparator=1;
varPattern="*";


#parse input paramters
echo -e -n $redText;
origIfs=$IFS;
for paramPair in "$@"; do
    ([[ $paramPair == "-" ]] || [[ $paramPair == "--" ]]) && continue;
	
	#thos starting with "-" are commands
	if [[ ${paramPair:0:1} == "-" ]]; then
		if [[ $paramPair == *"="* ]]; then #contain =
			IFS='=';
			read -ra paramContents <<< "$paramPair";
			paramKey=${paramContents[0]};
			paramValue=${paramContents[1]};
		else
			paramKey=$paramPair;
			unset paramValue;
		fi
		
		
		#if paramValue is empty, invert the default value, else use that value
		#about branches
		if [[ ${boolBranchesDivergentOnlyKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolBranchesDivergentOnly=`invert.sh $boolBranchesDivergentOnly` || boolBranchesDivergentOnly=`bool.sh $paramValue`;
		elif [[ ${boolBranchesWithUpstreamOnlyKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolBranchesWithUpstreamOnly=`invert.sh $boolBranchesWithUpstreamOnly` || boolBranchesWithUpstreamOnly=`bool.sh $paramValue`;
		
		#about info
		elif [[ ${boolInfoHeaderKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolInfoHeader=`invert.sh $boolInfoHeader` || boolInfoHeader=`bool.sh $paramValue`;
		elif [[ ${strInfoHighlightedBranchKeys[@]} =~ $paramKey ]]; then
			if [[ -z $paramValue ]]; then
				echo "*** Invalid value:[$paramValue] for key:[$paramKey] ***";
			else 
				tmpResult=`git rev-parse --verify $paramValue`;
				if [[ -z $tmpResult ]]; then # the branch not exist
					echo "*** Highlighted branch:[$paramValue] doesn't exist ***";
					unset strInfoHighlightedBranch;
				else
					strInfoHighlightedBranch=$paramValue;
				fi
			fi
		elif [[ ${boolInfoRemoteKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolInfoRemote=`invert.sh $boolInfoRemote` || boolInfoRemote=`bool.sh $paramValue`;
		elif [[ ${boolInfoCommitKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolInfoCommit=`invert.sh $boolInfoCommit` || boolInfoCommit=`bool.sh $paramValue`;
		elif [[ ${intInfoCommitLinesKeys[@]} =~ $paramKey ]]; then
			[[ ! -z $paramValue ]] && [[ $paramValue =~ ^[0-9]+$ ]] && intInfoCommitLines=$paramValue || echo "*** Invalid value:[$paramValue] for key:[$paramKey] ***";
		elif [[ ${boolInfoDescriptionKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolInfoDescription=`invert.sh $boolInfoDescription` || boolInfoDescription=`bool.sh $paramValue`;
		elif [[ ${boolInfoRankKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolInfoRank=`invert.sh $boolInfoRank` || boolInfoRank=`bool.sh $paramValue`;
		
		#others
		elif [[ ${boolInteractiveKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolInteractive=`invert.sh $boolInteractive` || boolInteractive=`bool.sh $paramValue`;
		elif [[ ${boolSeparatorKeys[@]} =~ $paramKey ]]; then
			[[ -z $paramValue ]] && boolSeparator=`invert.sh $boolSeparator` || boolSeparator=`bool.sh $paramValue`;
			
		else
			echo "*** Unknown key:[$paramKey] ***";
		fi
		
	else
		varPattern=$paramPair;
	fi
done
IFS=$origIfs;
echo -e -n $resetText;

#post-processing of parameters=====================================
#add heading and trailing * to pattern if it doesn't exist
[[ ${varPattern:0:1} != "*" ]] && varPattern="*"$varPattern;
[[ ${varPattern: -1} != "*" ]] && varPattern=$varPattern"*";

#========================================================
[[ -z $intInfoCommitLines ]] && commitContents="contents:subject" || commitContents="contents:lines=$intInfoCommitLines";
declare -r formatString="isHead=%(HEAD) branchName=%(refname:short) sha=%(objectname:short) commitTitle=%($commitContents) upstream=%(upstream) push=%(push)"
git for-each-ref --shell --format="$formatString" refs/heads/"$varPattern" | \
while read entry; do #it must be "entry"
	#escape characters:
	entry=${entry//'"'/'\"'} #" --> \"
	entry=${entry//"'''"/${QUOTE}} #''' --> ${QUOTE}
	entry=${entry//"'"/'"'} #' --> "
	entry=${entry//${QUOTE}/"'"} #${QUOTE} --> '
	
	upstream="${upstream// }"
	push="${push// }"
	
	# echo "test: $entry"
	set -f;#disable globbing
	eval "$entry"
	set +f;#enable globbing

	#======================================================================
	#check whether upstream exists ========================================
	[[ -z $upstream ]] && upstreamExists=0 || upstreamExists=1;
	[[ $boolBranchesWithUpstreamOnly -eq 1 ]] && [[ $upstreamExists -eq 0 ]] && continue;
	
	#check divergence type ==================================================
	if [[ $upstreamExists -eq 1 ]]; then
		#get the latest commit on specified branch:
		latestCommit=`git show-ref --heads -s $branchName`;
		upstreamCommit=`git show-ref -s ${upstream//"refs/remotes/"/}`;
		mergeBaseCommit=`git merge-base $branchName $upstream`;
		
		if [[ $upstreamCommit == $mergeBaseCommit ]]; then
			[[ $latestCommit == $upstreamCommit ]] \
				&& divergenceType=$TYPE_EXACT \
				|| divergenceType=$TYPE_CONVERGENT
		else
			divergenceType=$TYPE_DIVERGENT;
		fi
	fi
	[[ $boolBranchesDivergentOnly -eq 1 ]] && [[ $divergenceType -ne $TYPE_DIVERGENT ]] && continue;
		
	#=======================================================================
	#start to echo this branch==============================================
	echo -n $resetText;
	[[ $boolSeparator -eq 1 ]] && printf "=%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
	#one line vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	#header --------------------------------------------------------
	headerColor=$resetText;
	if [[ $boolInfoHeader -eq 1 ]]; then 
		headerAbbr=${branchName:0:1};#extrieve the first character
		headerAbbr=${headerAbbr^^};#to upper case
		echo -e -n $headerColor"$headerAbbr ";
	fi
	
	#branchName ------------------------------------------------------
	if [[ -z $strInfoHighlightedBranch ]]; then 
		[[ "$isHead" == "*" ]] && branchNameColor=$greenText$invertEnable || branchNameColor=$magentaText;
	else 
		[[ $strInfoHighlightedBranch == $branchName ]] && branchNameColor=$greenText$invertEnable || branchNameColor=$magentaText;
	fi
	# [[ $upstreamExists -eq 0 ]] && branchNameColor=$branchNameColor$dimEnable
	echo -e -n $branchNameColor"$branchName "$invertDisable$dimDisable;
		
	#divergence type ------------------------------------------------
	if [[ $upstreamExists -eq 1 ]]; then
		echo -n -e $yellowText"\t";
		case $divergenceType in
			$TYPE_DIVERGENT ) #------------------------------------------------------------------------
				echo -n -e $invertEnable"Divergent"$invertDisable;;
			$TYPE_CONVERGENT ) #------------------------------------------------------------------------
				echo -n -e "Convergent";;
			$TYPE_EXACT ) #------------------------------------------------------------------------
				echo -n -e "Exact";;
			* )
				echo "*** Unknown DivergenceType ***";;
		esac
		echo -n -e $resetText;
	fi
	
	#rank ---------------------------------------------------
	if [[ $boolInfoRank -eq 1 ]]; then
		rank=$((`git config branch.$branchName.rank`));
		if [[ $rank =~ ^[0-9]+$ ]] && [[ $rank -gt 0 ]]; then
			# former regex: positive integer or zero
			printf "\t$redText%3d) " $rank;
			# \xE2\x98\x85 is UTF-8 form of unicode ★
			printf '\xE2\x98\x85 %.0s' `eval echo {1..$rank}`
		fi
	fi
	echo ;
	#one line ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	
	#remote related ====================================================
	if [[ $boolInfoRemote -eq 1 ]]; then
		[[ ! -z $upstream ]] && echo -e $headerColor"\tupstream: "$greenText"$upstream";
		[[ ! -z $push ]] && echo -e $headerColor"\tpush: "$greenText"$push";
	fi
	
	#commit content =================================================
	#tmp solution to break lines with specified token " - "; bug: successive tokens will produce unwanted result
	if [[ $boolInfoCommit -eq 1 ]]; then
		commitTitle=${commitTitle//' - '/"\n\t                 - "}
		echo -e $headerColor"\tCommit: $sha "$cyanText"$commitTitle";	
	fi
	
	#description ====================================================	
	if [[ $boolInfoDescription -eq 1 ]]; then
		description=`git config branch.$branchName.description`;
		if [[ ! -z "${description// }" ]]; then
			description=${description//' - '/"\n\t\t - "} #why can't I add more spaces???
			echo -e $headerColor"\tDescription: "$yellowText$description;
		fi
	fi
done
