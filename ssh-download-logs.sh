#!/bin/bash

# REM - Remote
# LOC - Local
REMLOG=""
LOCBASEPATH=""
DATELOG=`date "+[%F %H:%M]"`
TEMPORAL=""
UNIFIEDLOG="$LOCBASEPATH/unified.log"
FILENAME=""

# All servers you need to access (split with spaces)
IPS=() 

USER=""
SSHKEY=""

# ==== SCRIPT ====

for ip in ${IPS[*]}; do
        DEBUG="$LOCBASEPATH/script.log"
        touch "$DEBUG"
        TEMPORAL="$LOCBASEPATH/$ip/tmp"
        mkdir -p "$TEMPORAL"

        scp -q -i $SSHKEY $USER@$ip:$REMLOG $TEMPORAL
        remotefilepath="$TEMPORAL/$FILENAME"

        if [ -f $remotefilepath ]; then
                remotelinesnumber=`wc -l $remotefilepath | cut -d' ' -f1`
                re='^[0-9]+$'
                if ! [[ $remotelinesnumber =~ $re ]] ; then
                        remotelinesnumber=0
                fi
                localfilepath="$LOCBASEPATH/$ip.log"
                locallinesnumber=0
                if [[ -f $localfilepath ]]; then
                        locallinesnumber=`wc -l $localfilepath | cut -d' ' -f1`
                else
                        touch $localfilepath
                fi
                if [ $remotelinesnumber -gt $locallinesnumber ]; then
                        linesnumber=`expr $remotelinesnumber - $locallinesnumber`
                        tail --lines=$linesnumber $remotefilepath >> "$localfilepath"
                        tail --lines=$linesnumber $remotefilepath >> "$UNIFIEDLOG"
                        echo "Added $linesnumber lines to file $ip.log" >> $DEBUG
                elif [ $remotelinesnumber -eq $locallinesnumber ]; then
                        echo "No new lines found on $ip" >> $DEBUG
                else
                        echo "[ERROR] More lines found in local than in remote file $ip" >> $DEBUG
                fi

                # Deleting auxiliar files
                rm -rf "$LOCBASEPATH/$ip"
        else
                echo "[ERROR] File $FILENAME doesn't exist at $ip" >> $DEBUG
        fi
done
