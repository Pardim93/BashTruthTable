#!/bin/bash

echo "Truth Table"

n="START" ; p="" ; f="" ; aux=""

# NEGATION (NOT or !) wont work in the conventional way, unfortunately you cant choose the location of the trailing parenthesis
# Rather it will take the last 2 premisses p, q of current time and apply the Morgan`s law
# so when you choose the NOT option, it will go to the last 2 premisses of your chain 
# the chain will be solved from left to right only
function morgan_law {
	# aplly De Morgan`s Law on the predicate
	# if it is not(p or q) =>  (not p) and (not q) 
	# if it is not(p and q) =>  (not p) or (not q)
	# just not(p) if there is no disjunction  or conjunction
	if [[ "$aux" = *"{0..1}\"&&\""* ]]; then
		aux="!{0..1}\"||\"!"
	elif [ "$f" == "" ]; then 
		aux="!$aux"
	else
    	aux="!{0..1}\"&&\"!"
	fi
}

function show_results {

	p="$p$aux{0..1}"
	for i in $(eval "echo $p"); 
	do 
  		(( "result=(($i))" )); 
  		echo "$i" = "$result"; 
	done
}

function get_input {
	while [ -n "$n" ] 
	do
		printf  "Press 1 to Add AND(&&) \nPress 2 to add OR(||)\nPress 3 to add NOT(!)\nPress Enter to eval\n"
		read -r n 
	
		if [ -n "$n" ]
		then
	
			if [ "$n" == 1 ]
			then
				p="$p$aux"
				aux="{0..1}\"&&\""
				f="1"
			elif [ "$n" == 2 ]
			then
				p="$p$aux"
				aux="{0..1}\"||\""
				f="1"		
			elif [ "$n" == 3 ]
			then
				morgan_law $aux
			fi
		fi
	done

	show_results
}

# Get user Input 
get_input


