#!/bin/bash
gitDir=`git rev-parse --git-dir`;
rebaseApplyDir=`ls $gitDir | grep rebase`;
[[ -z $rebaseApplyDir ]] && echo 0 || echo 1
