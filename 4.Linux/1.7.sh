#!/bin/bash
# unit-conversion.sh

# Написать скрипт преобразующий метры в мили. В качестве входящего аргумента
# должна быть цифра - метры. В стандартный вывод вывести количество миль.

#echo "$1" | awk '{printf("%.5f miles\n",$1*0.00062)}'

result=$(bc<<<"scale=2;$1*0.00062")
result=$(echo $result | sed -e 's/^\./0./' -e 's/0\{1,\}$//')
echo "$result miles"

exit 0