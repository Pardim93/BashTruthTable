#!/bin/bash
#o Tabela And; for i in {0..1}+{0..1}+{0..1}; do let "a =$i" ;echo $i = "$a";  done

echo "Truth Table"

n="START"	
a=" {0..1}"
while [ ! -z "$n" ]
do 
  printf  "Press 1 to Add AND(&&) \nPress 2 to add OR(||)\nPress Enter to confirm\n"i
  read n 
  
 if [ ! -z "$n" ]
 then
 
    if [ $n == 1 ]
    then
      a="$a\"&&\""{0..1}
      echo $a
    fi
    
    if [ $n == 2 ]
    then
      a="$a\"||\""{0..1}
      echo $a
    fi
  
  fi
done

 
www="for i in  $a"
echo $www
eval "$www ; do let \"result = (($i))\" ; echo \"$result\"; done"

#echo $command
#eval $command
#echo $a
#eval $a
#for i in  eval $a
#do 
#let "result  = (($i))" 
#echo $result
#done


