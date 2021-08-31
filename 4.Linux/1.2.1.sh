#!/bin/bash
echo "Input directory name:"
read NAME
echo "Input depth:"
read DEPTH
echo "Input max iterations:"
read ITER
function mkstruct {
  if [ $1 -le $(($DEPTH)) ]
  then
    DIRS=$RANDOM
    let "DIRS%=ITER"
    NUM=1
    while [ "$NUM" -le $(("$DIRS")) ]; do
      NAMESUBDIR="$2$NUM"
      mkdir "$NAMESUBDIR"
      cd "$NAMESUBDIR"
      mkstruct $(( $1 + 1 )) $NAMESUBDIR
      NUM=$(($NUM+1))
    done
  fi
  cd ".."
}
mkdir "$NAME"
cd "$NAME"
mkstruct 1 "dir"
