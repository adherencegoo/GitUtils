#!/bin/bash
usage="Usage: [<inputPattern>(can't start with \"-\")] [--nullable]"	
	
#IO redirection=============================
fdReturn=121; #TODO: get an unused fd instead of direct assignment
eval exec "$fdReturn>&1" # Save current "value" of stdout.
exec 1>/dev/tty #redirect stdout to console

#handle inputs==============================================
unset inputPattern;
isNullable="false";
for arg in $@; do 
	if [[ $arg == "--nullable" ]]; then
		isNullable="true";
	elif [[ $arg =~ ^[^-]*$ ]] && [[ ${arg// } ]]; then #not start with - && not empty
		inputPattern=$arg;
	fi
done

# if [[ $# -eq 0 ]]; then
	# echo $usage;
	# exit;
# fi

echo "isNullable:"$isNullable
echo "inputPattern:"$inputPattern
echo



#get branch(es): original output will include "*" and it's catenated as a string
#remove '\n', replace "*" with one space
branches=`git branch --list $inputPattern | tr -d '\n' | tr '*' ' '`; 
IFS='  ' #two spaces !!!
read -r -a branches <<< "$branches" #split string to array

echo "test:-------------";
echo '${#branches[@]}:'${#branches[@]}
IFS="......"
echo '${branches[@]}:['${branches[*]}']'
echo "test:-------------";
echo;


if [[ ${#branches[@]} -eq 0 ]]; then
	if [[ $isNullable == "false" ]]; then
		echo "tmp: use head"; #TODO: not correct if more than one branch pointing to current commit
		echo `git name-rev --name-only HEAD` >&$fdReturn;
	else
		echo "test... isNullable=\"true\""
	fi
elif [ ${#branches[@]} -eq 1 ]; then
	echo "tmp: directly hit";
	echo ${branches[@]} >&$fdReturn
else # more than one
	#TODO
	echo "TODO: more than one: "${branches[@]};
fi
