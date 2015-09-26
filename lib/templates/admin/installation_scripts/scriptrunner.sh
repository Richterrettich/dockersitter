#!/bin/bash

if [ $# == 0 ] || [ $# -gt 1 ]; then
	echo wrong number of arguments;
	exit 1;
fi

DIR=$1

LAST_CHAR=${DIR: -1}

if [ $LAST_CHAR != "/" ]; then
	DIR=$DIR/;
fi

for f in $(ls $DIR*| sort -t _ -k 1 -g); do 
	sh $f;
done
