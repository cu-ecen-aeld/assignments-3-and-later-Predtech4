#!/bin/bash

if [ $# != 2 ] 
then
    echo ERROR: there are $# parameters when there are 2 needed
    exit 1
elif [ ! -d $1 ]    
then
    echo ERROR: first parameter is not a directory \(but should be\)
    exit 1
fi

var1=$(find $1 -type f | wc -l)
var2=$(grep -o -r $2 $1 | wc -l)

echo The number of files are $var1 and the number of matching lines are $var2
