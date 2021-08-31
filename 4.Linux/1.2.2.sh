#!/bin/bash
if [ "$1" == "$2" ]
then
  echo "Names are equal."
  exit
fi
PATH1=`sudo find / -type d -name "$1"`
PATH2=`sudo find / -type d -name "$2"`
echo "$1"
echo "$2"
echo "$PATH1"
echo "$PATH2"
if [ "$PATH1" == "" ]
then
  echo "Source dir doesn't exist."
  exit
fi
if [ "$PATH2" == "" ]
then
  echo "Destination dir doesn't exist."
  exit
fi
if [[ "$PATH1" == *"$PATH2"* ]]
then 
  echo "Source dir is a subdir for the second one."
elif [[ "$PATH2" == *"$PATH1"* ]]
then
  echo "Destination dir is a subdir for the first one."
fi
DUP1=`sudo du -s "$PATH1"`
DUP1=${DUP1%%/*}
DFP2=`sudo df "$PATH2"`
DFP2=${DFP2#*/}
DFP2=${DFP2#* }
DFP2=${DFP2% *}
DFP2=${DFP2% *}
DFP2=${DFP2# *}
DFP2=${DFP2#*     *}
DFP2=${DFP2#* *}
DFP2=${DFP2#* *}
DFP2=${DFP2# *}
echo "Disk usage of source directory: $DUP1"
echo "Free space on destination disk: $DFP2"
if [ "$DUP1" -le "$DFP2" ]
then
  cp -a $PATH1 $PATH2
  echo "Source directory was succesfully copied."
else
  echo "There are not enough space for copying source directory. Would you like to continue?[Y/N]"
  read -n 1 CON
  if [ "$CON"=="Y" ]
  then
    cp -a $PATH1 $PATH2
    echo "Source directory was succesfully copied."
  else
    echo "Operation was aborted."
  fi
fi