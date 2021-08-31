#!/bin/bash

echo "Количество дней, прошедших с начала года: `date +%j`."

echo "Количество секунд, прошедших с 01/01/1970 : `date +%s`."

prefix=temp
suffix=`eval date +%s` 
filename=$prefix.$suffix
echo $filename

exit 0