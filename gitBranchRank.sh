#!/bin/bash
# Usage:
	# $rankVal:
		# not set: get value
		# 0: unset
		# 5: set to 5
		# +5: inc by 5
		# -5: dec by 5
	# $branchName:
		# not set: use HEAD branch
	
#handle inputs==============================================
unset rankVal;
unset branchName;
for arg in $@; do 
	if [[ $arg =~ ^[+-]?[0-9]+$ ]]; then 
		rankVal=$arg;
	else
		branchName=$arg;
	fi
done

#if branchName(space removed) is not specified, use HEAD
[[ -z ${branchName// } ]] && branchName=`git name-rev --name-only HEAD`;
#TODO: if branchName is set but not valid, treat it as regex

#debug:
# echo rankVal: $rankVal
# echo branchName: $branchName

if [[ -z $rankVal ]]; then #not set, display it
	echo `git config branch.$branchName.rank`;
elif [[ 0 -eq $rankVal ]]; then #numerical comparison, equal to 0: unset rank
	git config --unset branch.$branchName.rank
	echo "Unset rank of $branchName";
	
	#remove section if it's empty after unsetting this setting
	sectionContent=`git config --get-regex "^branch.$branchName.*"`;
	if [[ -z ${sectionContent// } ]]; then
		git config --remove-section branch.$branchName
		echo "Remove empty section: branch.$branchName";
	fi
elif [[ $rankVal =~ ^[0-9]+$ ]]; then #not start with + or -: set rank
	git config branch.$branchName.rank $(($rankVal)) #numerical form
	echo "Rank of $branchName: $rankVal";
else #inc or dec
	newRank=$(( `git config branch.$branchName.rank` + $rankVal ));
	[[ $newRank -lt 0 ]] && newRank=0; #newRank must >= 0 and contains no +-
	eval $(basename $0) $branchName $newRank; #recursive call
fi

unset sectionContent;
unset arg;
unset newRank;
unset rankVal;
unset branchName;