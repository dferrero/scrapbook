#!/bin/bash

IFS="
"

videoPath="/home/pi/Videos"
videoList=""
#space=" "
#for vid in `ls $videoPath`; do
#	videoList=$videoList$vid$space 
#done	
#echo $videoList
cd $videoPath
vlc -LZf * > /dev/null
