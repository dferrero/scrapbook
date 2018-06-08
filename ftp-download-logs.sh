#!/bin/sh

HOST=''
USER=''
PASSWD=''
FILES='*.LOG'
DATE=`date "+%Y-%m-%d %H:%M"`

ROOTPATH=""
FTPLOG="$ROOTPATH/ftp.log" # Output from all ftp commands executed
SCRIPTLOG="$ROOTPATH/application.log"
PATHLOGS="$ROOTPATH/logs"
PATHNEWLOGS="$PATHLOGS/new-logs"

# Sometimes the ftp command stays as a zombie process. We look for it and, if it appears, we will kill it
# NOTE: Careful if you have more process related to ftp
zombies=`pgrep -lf "ftp -nv" | wc -l`
if [[ $zombies -ne 0 ]]; then
        pkill -f "ftp -nv"
fi

# Retrieve logs from ftp
cd $PATHNEWLOGS
ftp -nv $HOST>>$FTPLOG <<END_SCRIPT
prompt
quote USER $USER
quote PASS $PASSWD
binary
mget $FILES
quit
END_SCRIPT

for file in `ls *.TXT`; do
        if [ ! -f "$PATHLOGS/$file" ]; then
                touch "$PATHLOGS/$file"
                echo "[$DATE] Created file $file" >> $SCRIPTLOG
        fi
        totallines=`wc -l "$PATHNEWLOGS/$file" | cut -d' ' -f1`
        storedlines=`wc -l "$PATHLOGS/$file" | cut -d' ' -f1`
        newlines=$((totallines - storedlines))
        echo "[$DATE] File: $file | New lines: $newlines | Stored lines: $storedlines" >> $SCRIPTLOG
        if [[ $newlines -ne 0 ]]; then
                if [[ $newlines -gt 0 ]]; then
                        tail -n $newlines "$PATHNEWLOGS/$file" >> "$PATHLOGS/$file"
                        echo "[$DATE] Added $newlines new lines to $file" >> $SCRIPTLOG
                else
                        echo "[$DATE] [ERROR] $file - More lines on stored file than remote file" >> $SCRIPTLOG
                fi
        fi
        rm -rf "$PATHNEWLOGS/$file"
done
