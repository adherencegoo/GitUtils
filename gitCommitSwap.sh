#!/bin/bash
targetBranch=$1;
if [ -z $targetBranch ]
then #true if $targetBranch string is null
	echo -n "Enter target branch: ";
	read targetBranch #get user input and save to the variable
fi

tmpBranch="orig-"$targetBranch;

#TODO make sure both commits have no other branches pointing on them

git logg $targetBranch -2
printf "~%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
echo -n -e "\n\tSwap the 2 commits (y/N) ? ";
read inputAction;

if [[ ${#inputAction[@]} -eq 1 ]] && [[ $inputAction == "y" ]]; then 
	resetText=`tput sgr0`
	redText=`tput setaf 1`
	greenText=`tput setaf 2`
	yellowText=`tput setaf 3`
	magentaText=`tput setaf 5`
	cyanText=`tput setaf 6`

	origNewerMsg=`git log --format=%B -1 $targetBranch`
	origOlderMsg=`git log --format=%B -1 ${targetBranch}~`

	echo "Message should be used in revert:";
	printf "v%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
	echo
	echo -e $greenText"$origOlderMsg"$resetText
	printf "^%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
	echo
	
	git checkout $targetBranch
	git revert $targetBranch #TODO set message: origOlderMsg
	git branch $tmpBranch
	git reset HEAD~ --hard
	git reset HEAD~2 --soft
	git commit -m "$origNewerMsg"
	git cherry-pick $tmpBranch
	
	echo -e $yellowText"Need to manually delete branch: $tmpBranch"$resetText
	# printf "~%.0s" `eval echo {1..$(tput cols)}`;#depends on window width
	# echo -n -e "\n\tDelete branch: $tmpBranch (y/N) ? ";
	# read inputAction;
	# if [[ ${#inputAction[@]} -eq 1 ]] && [[ $inputAction == "y" ]]; then 
		# git branch -D $tmpBranch
	# fi
fi
