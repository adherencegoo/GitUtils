#!/bin/bash
# Usage: if $baseBranch is not set, manually enter it

#handle input
baseBranch=$1
if [ -z $baseBranch ]
then #true if $baseBranch string is null
	echo -n "Enter base branch: "; #-n: no new line
	read baseBranch #get user input and save to the variable
fi

#TODO check if baseBranch exists

baseCommit=`git show-ref --heads -s $baseBranch`; #get the latest commit on the branch:
branches=`git for-each-ref refs/heads/ --format='%(refname:short)'`; #get all branches

divergentBranches=() #array
for branch in $branches; do
	tmpMergeBase=`git merge-base $branch $baseBranch`;
	if [ "$baseCommit" != "$tmpMergeBase" ]; then #this branch is divergent from baseBranch
		divergentBranches+=($branch) #push element to array
	fi
done

#test: not used
# unset divergentBranches;
# divergentBranches=`git for-each-ref refs/heads/ --merged $baseCommit --format='%(refname:short)' `
# divergentBranches=`git for-each-ref refs/heads/ --format='%(refname:short)' --no-merged $baseCommit `
# divergentBranches=`git for-each-ref refs/heads/ --contain $baseCommit --format='%(refname:short)'`
# echo tmp:~~ count:${#divergentBranches[@]}, ${divergentBranches[@]}

unset baseCommit;

if [ ${#divergentBranches[@]} -eq 0 ]; then #empty
    echo -e "\n\tAll branches are convergent w.r.t. \"$baseBranch\" ~";
else
	resetText=`tput sgr0`
	redText=`tput setaf 1`
	greenText=`tput setaf 2`
	yellowText=`tput setaf 3`
	magentaText=`tput setaf 5`
	cyanText=`tput setaf 6`
	
	stateHasConflicts=`gitIsRebasing.sh`;
	selfName=$(basename $0);
	
	dimEnable="\e[2m";
	dimDisable="\e[22m";
	
	headBeforeBash=`git rev-parse --abbrev-ref HEAD`;
	[[ $headBeforeBash == "HEAD" ]] && unset headBeforeBash;

	stateAutoRebaseOn=0;
	skippedDivergentBranches=() #array
	#take action on them one by one
	for handlingBranch in ${divergentBranches[@]}; do
	
		[[ $handlingBranch =~ ^.*[-][xX]$ ]] && continue; #ignore branch with trailing -x or -X
	
		looping=1;
		while [ $looping -eq 1 ]; do
			
			gitOrigHead=`git rev-parse --abbrev-ref ORIG_HEAD`;
			gitHead=`git rev-parse --abbrev-ref HEAD`;
			[[ $gitHead == "HEAD" ]] && gitHead='DetachedHead';
		
			#simulated command line======================================
			printf "=%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
			echo -e -n ${magentaText}$selfName" "; #short file name
			echo -e -n ${yellowText}${PWD##*/}" "; #yellow short current directory
			if [ $stateHasConflicts -eq 1 ]; then
				echo -e -n ${cyanText}"(ORIG_HEAD: "$gitOrigHead"|REBASE) ";
			else
				echo -e -n ${cyanText}"(HEAD: "$gitHead") ";#name of current branch
			fi
			echo -n ${redText}"(Base: "$baseBranch")";
			echo ;
			
			#show all divergentBranches======================================
			if [ $stateHasConflicts -eq 1 ]; then
				echo "${resetText}*** Executing ${redText}\"git rebase $gitHead(HEAD) $gitOrigHead(ORIG_HEAD)\" ${resetText}***";
			fi
			echo -n ${resetText}"Take action on divergent branch: ";
			for idx in ${!divergentBranches[@]}; do
				[ $(( $idx%8 )) -eq 0 ] && echo;
			
				tmpBranch=${divergentBranches[$idx]};
				[[ $tmpBranch =~ ^.*[-][xX]$ ]] && echo -e -n $dimEnable;
				if [ $handlingBranch == $tmpBranch ]; then
					echo -n ${greenText}"  * "$tmpBranch;
				else
					echo -n ${yellowText}"    "$tmpBranch;
				fi
				echo -e -n $dimDisable;
			done
			echo ${resetText};
			
			#enable/disable cmd==========================
			#TODO
			enableRebaseAbort=$stateHasConflicts;
			enableRebaseConti=$stateHasConflicts;
			enableRebase=`invert.sh $stateHasConflicts`;
			
			if [ $stateHasConflicts -eq 1 ]; then
				enableAutoRebase=0;
				stateAutoRebaseOn=0;
			else
				if [[ $stateAutoRebaseOn -eq 1 ]]; then
					enableAutoRebase=0;
				else
					enableAutoRebase=1;
				fi
			fi
			enableSkip=1;
						
			#define cmd body===============================
			cmdRebaseAbort="git rebase --abort";
			cmdRebaseConti="git rebase --continue";
			cmdRebase="git rebase $baseBranch $handlingBranch";
						
			#show enabled cmds=================================
			[[ $enableRebaseAbort -eq 1 ]] && echo -e ${cyanText}"\t- a: "${resetText}$cmdRebaseAbort;
			[[ $enableRebaseConti -eq 1 ]] && echo -e ${cyanText}"\t- c: "${resetText}$cmdRebaseConti;
			[[ $enableRebase -eq 1 ]] && echo -e ${cyanText}"\t- b: "${resetText}$cmdRebase;
			[[ $enableAutoRebase -eq 1 ]] && echo -e ${cyanText}"\t- all: auto rebase for all non-ignored branches"${resetText};
			[[ $enableSkip -eq 1 ]] && echo -e ${cyanText}"\t- s: (skip this branch) "${resetText};
			echo -e -n "\t"${resetText}"$ ";
			
			#read cmd==============================================
			if [[ $stateAutoRebaseOn -eq 1 ]]; then
				currentCmd="b";
				echo $currentCmd;
			else
				read -e currentCmd;#-e: to avoid the unexpected effect of arrow keys
			fi
			printf "_%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
			
			#execute cmd==============================================
			case $currentCmd in
				"a" ) #------------------------------------------------------------------------
					if [[ $enableRebaseAbort -eq 1 ]]; then
						echo "$ "$cmdRebaseAbort;
						$cmdRebaseAbort;
						
						stateHasConflicts=0;
						looping=$stateHasConflicts;
					fi
					;;
				"c" ) #------------------------------------------------------------------------
					if [[ $enableRebaseConti -eq 1 ]]; then
						echo "$ "$cmdRebaseConti;
						$cmdRebaseConti;
						
						stateHasConflicts=`gitIsRebasing.sh`; 
						looping=$stateHasConflicts; #if stateHasConflicts, still keep looping
						[[ $stateHasConflicts -eq 0 ]] && echo $yellowText"[$cmdRebase] succeeds!"$resetText;
					fi
					;;
				"b" ) #------------------------------------------------------------------------
					if [[ $enableRebase -eq 1 ]]; then
						echo "$ "$cmdRebase;
						$cmdRebase;
						
						stateHasConflicts=`gitIsRebasing.sh`; 
						looping=$stateHasConflicts; #if stateHasConflicts, still keep looping
						[[ $stateHasConflicts -eq 0 ]] && echo $yellowText"[$cmdRebase] succeeds!"$resetText;
					fi
					;;
				"all" ) #------------------------------------------------------------------------
					[[ $enableAutoRebase -eq 1 ]] && stateAutoRebaseOn=1;
					;;
				"s" ) #------------------------------------------------------------------------
					[[ $enableSkip -eq 1 ]] && looping=0;
					;;
				* ) #------------------------------------------------------------------------
					#disable some commands
					if [[ "$currentCmd" == *"rebase"* ]] \
						|| [[ "$currentCmd" == *$selfName* ]] \
						|| [[ "$currentCmd" == *"rename"* ]] \
						|| [[ "$currentCmd" == *"branch -m"* ]] \
						|| [[ "$currentCmd" == *"divergent"* ]]; then 
						echo $redText"*** cmd [$currentCmd] is not allowed in "$selfName" ***"$resetText;
					else
						echo "$ "$currentCmd;
						$currentCmd;
					fi
					;;
			esac
		done #action loop
	done #for each divergent branch
	[[ ! -z $headBeforeBash ]] && git checkout $headBeforeBash
fi 
