#!/bin/bash

# If, for some reason, you need to use different parsers in the same file,
# you can split into differente files with the same structure log.

# ==== VARIABLES ====
ORIGINPATH=""
DESTINATIONPATH=""

# Events, audit and sessions are three examples
EVENTS="$DESTINATIONPATH/events.log"
AUDIT="$DESTINATIONPATH/audit.log"
SESSIONS="$DESTINATIONPATH/sessions.log"

# ==== SCRIPT ====

for file in `ls -tr $ORIGINPATH | tail -n 3`;
do
        originfilepath="$ORIGINPATH/$file"
        destinationfilepath="$DESTINATIONPATH/$file"

        event=`echo $file | grep Event | wc -l`
        audit=`echo $file | grep Audit | wc -l`

        # echo "Fichero a procesar: $file"

        originlines=`cat $originfilepath | wc -l`
        destinationlines=0
        if [ -f $destinationfilepath ]; then
                destinationlines=`cat $destinationfilepath | wc -l`
        fi

        newlines=$((originlines - destinationlines))
        if [[ $newlines -gt 0 ]]; then
                tail -n $newlines $originfilepath >> "$destinationfilepath"

                if [[ $event -gt 0 ]]; then
                        tail -n $newlines $originfilepath | sed 's/\t/\|/g' >> "$EVENTS"
                elif [[ $audit -gt 0 ]]; then
                        tail -n $newlines $originfilepath | sed 's/\t/\|/g' >> "$AUDIT"
                else
                        tail -n $newlines $originfilepath | sed 's/\t/\|/g'>> "$SESSIONS"
                fi
        fi
done
