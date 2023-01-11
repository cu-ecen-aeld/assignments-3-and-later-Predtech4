#!/bin/bash

if [ $# != 2 ] 
then
    echo ERROR: there are $# parameters when there are 2 needed
    exit 1
fi

mkdir -p "$(dirname "$1")" && touch "$1"


echo $2 > $1
