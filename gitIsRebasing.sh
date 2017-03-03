#!/bin/bash
gitDir=`git rev-parse --git-dir`;
rebaseApplyDir=`ls $gitDir | grep rebase`;
if [ -z $rebaseApplyDir ]; then #not rebasing
	echo "false" ;
else #there are conflicts
	echo "true";
fi
