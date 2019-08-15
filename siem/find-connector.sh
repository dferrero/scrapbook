#!/bin/bash

# Usage: $0 <what are we looking for in agent.properties> [<path to search agent.properties files>]

DEFAULT="/home/arcsight"
path=""

if [[ $# -eq "2" ]]; then
	path=$2
else
	path=$DEFAULT
fi

if [ -d $path ]; then
	echo "File path $path doesn't exist. Exiting..."
	exit 1
fi

for elem in `find $path -name agent.properties`; do
        num=`grep $1 $elem | wc -l`
        if [[ $num -ne 0 ]]; then
                echo $elem
        fi
done