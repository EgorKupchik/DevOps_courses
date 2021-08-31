#!/bin/bash

# Напишите скрипт который будет проводить симуляцию 700 бросков 6 гранного кубика.
# Вывод должен быть в следующем формате:
#     echo "единиц   =   $ones"
#     echo "двоек    =   $twos"
#     echo "троек    =   $threes"
#     echo "четверок =   $fours"
#     echo "пятерок  =   $fives"
#     echo "шестерок =   $sixes"

ones=0
twos=0
threes=0
fours=0
fives=0
sixes=0

for ((i=1;i<=700;i++)) 
do
let "a = $RANDOM % 6 + 1"
case $a in
1) 
let "ones++";;
2)
let "twos++";;
3)
let "threes++";;
4)
let "fours++";;
5)
let "fives++";;
6)
let "sixes++";;
esac
done

echo "единиц   =   $ones"
echo "двоек    =   $twos"
echo "троек    =   $threes"
echo "четверок =   $fours"
echo "пятерок  =   $fives"
echo "шестерок =   $sixes"
exit 0