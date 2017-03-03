#!/bin/bash
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
	
	rebasing=`gitIsRebasing.sh`;
	selfName=$(basename $0);
	skippedDivergentBranches=() #array
	#take action on them one by one
	for handlingBranch in ${divergentBranches[@]}; do
	
		looping="true";
		while [ $looping == "true" ]; do
			
			gitOrigHead=`git name-rev --name-only ORIG_HEAD`;
			gitHead=`git name-rev --name-only HEAD`;
		
			#simulated command line======================================
			echo "======================================================";
			echo -e -n ${magentaText}$selfName" "; #short file name
			echo -e -n ${yellowText}${PWD##*/}" "; #yellow short current directory
			if [ $rebasing == "true" ]; then
				echo -e -n ${cyanText}"("$gitOrigHead"|REBASE) ";
			else
				echo -e -n ${cyanText}"("$gitHead") ";#name of current branch
			fi
			echo ;
			
			#show all divergentBranches======================================
			if [ $rebasing == "true" ]; then
				echo "${resetText}*** Executing ${redText}\"git rebase $gitHead(HEAD) $gitOrigHead(ORIG_HEAD)\" ${resetText}***";
			fi
			echo ${resetText}"Base branch: "${redText}$baseBranch ${resetText};
			echo -n ${resetText}"Take action on divergent branch: ";
			for idx in ${!divergentBranches[@]}; do
				[ $(( $idx%8 )) -eq 0 ] && echo;
			
				tmpBranch=${divergentBranches[$idx]};
				if [ $handlingBranch == $tmpBranch ]; then
					echo -n ${greenText}"  * "$tmpBranch;
				else
					echo -n ${yellowText}"    "$tmpBranch;
				fi
			done
			echo ${resetText};
			
			#action list======================================
			if [ $rebasing == "true" ]; then
				actionRebaseAbort="git rebase --abort";
				actionRebaseCont="git rebase --continue";
				
				echo -e ${cyanText}"\t- a: "${resetText}$actionRebaseAbort;
				echo -e ${cyanText}"\t- c: "${resetText}$actionRebaseCont;
			else
				actionRebase="git rebase $baseBranch $handlingBranch";
				# actionSudoCherry="actionSudoCherry TODO"
				# actionMarkIgnored="actionMarkIgnored TODO"
				
				echo -e ${cyanText}"\t- b: rebase: "${resetText}$actionRebase;
				# echo -e ${cyanText}"\t- c: sudo cherry-pick: "${resetText}$actionSudoCherry;
				# echo -e ${cyanText}"\t- g: make as ignored: "${resetText}$actionMarkIgnored;
			fi
			echo -e ${cyanText}"\t- s: skip this branch"${resetText};
			echo -e -n "\t"${resetText}"$ ";
			
			#take action======================================
			read action1;
			echo "------------------------------------------------------";
			if [[ ${#action1[@]} -eq 1 ]] && [[ $action1 == "s" ]]; then 
				looping="false";
			elif [[ "$action1" == *"rebase"* ]] \
				|| [[ "$action1" == *$selfName* ]] \
				|| [[ "$action1" == *"divergent"* ]]; then #disable some commands
				echo $redText"*** action [$action1] is not allowed in "$selfName" ***"$resetText;
			else #not skipped
				if [ $rebasing == "true" ]; then
					case $action1 in
						"a" ) #------------------------------------------------------------------------
							echo "$ "$actionRebaseAbort;
							$actionRebaseAbort;
							;;
						"c" ) #------------------------------------------------------------------------
							echo "$ "$actionRebaseCont;
							$actionRebaseCont;
							;;
						* ) #------------------------------------------------------------------------
							echo "$ "$action1;
							$action1;
							;;
					esac
					rebasing=`gitIsRebasing.sh`; 
					looping=$rebasing; #if rebasing, still keep looping
				else #not rebasing
					case $action1 in
						"b" ) #------------------------------------------------------------------------
							echo "$ "$actionRebase;
							$actionRebase;
							rebasing=`gitIsRebasing.sh`; 
							looping=$rebasing; #if rebasing, still keep looping
							;;
						* ) #------------------------------------------------------------------------
							echo "$ "$action1;
							$action1;
							rebasing=`gitIsRebasing.sh`; #redundant????
							;;
					esac
				fi #if rebasing
			fi #take action
		done #action loop
	done #for each divergent branch
fi 


unset baseBranch;
unset looping;
unset rebasing;
unset action1;
unset actionMarkIgnored;
unset actionRebase;
unset actionRebaseAbort;
unset actionRebaseCont;
unset actionSudoCherry;