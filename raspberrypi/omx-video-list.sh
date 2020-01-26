#!/bin/sh

# get rid of the cursor so we don't see it when videos are running
setterm -cursor off

# set here the path to the directory containing your videos
VIDEOPATH="/home/pi/Videos" 

# you can normally leave this alone
SERVICE="omxplayer"

# now for our infinite loop!
while true; do
        if ps ax | grep -v grep | grep $SERVICE > /dev/null; then
        echo "En el true"
	sleep 1;
else
	echo "En else"
        for entry in $VIDEOPATH/*; do
                clear
                omxplayer -r --no-osd $entry > /dev/null
        done
fi
done
