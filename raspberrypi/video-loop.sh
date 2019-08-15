#!/bin/bash
# This script plays the videos in the VPATH directory in a loop

# IMPORTANT: add it to ~/.bashrc to execute after login

# Path of the directory containing the videos 
VPATH="/home/pi/Videos"

# Loop through each file in VPATH until stopped 
while true; do 
	if ps ax | grep -v grep | grep omxplayer > /dev/null; then 
		sleep 1
	else 
		for entry in $VPATH/*; do 
			#clear 
			omxplayer -o hdmi -r --no-osd -b $entry > /dev/null 
		done 
	fi 
done

