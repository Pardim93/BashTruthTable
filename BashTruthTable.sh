#!/bin/bash

echo "Truth Table"

n="START"	
a=" {0..1}"
while [ ! -z "$n" ]

  printf  "Press 1 to Add AND(&&) \nPress 2 to add OR(||)\nPress Enter to eval\n"
  read n 
  
 if [ ! -z "$n" ]
 then
 
    if [ $n == 1 ]
    then
      a="$a\"&&\"{0..1}"
      echo $a
    fi
    
    if [ $n == 2 ]
    then
      a="$a\"||\"{0..1}"
      echo $a
    fi
  
  fi
done

for i in $(eval "echo $a"); do let "result = (($i))"; echo $i = "$result"; done


