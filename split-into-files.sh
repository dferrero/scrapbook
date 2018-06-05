#!/bin/bash

# ==== VARIABLES ====
RUTAORIGEN=""
RUTADEST=""

EVENTS="$RUTADEST/events.log"
AUDIT="$RUTADEST/audit.log"
SESSIONS="$RUTADEST/sessions.log"

# ==== SCRIPT ====

for fichero in `ls -tr $RUTAORIGEN | tail -n 3`;
do
        rutafichorigen="$RUTAORIGEN/$fichero"
        rutafichdest="$RUTADEST/$fichero"

        event=`echo $fichero | grep Event | wc -l`
        audit=`echo $fichero | grep Audit | wc -l`

        # echo "Fichero a procesar: $fichero"

        lineasorigen=`cat $rutafichorigen | wc -l`
        lineasdest=0
        if [ -f $rutafichdest ]; then
                lineasdest=`cat $rutafichdest | wc -l`
        fi

        nuevas=$((lineasorigen - lineasdest))
        if [[ $nuevas -gt 0 ]]; then
                tail -n $nuevas $rutafichorigen >> "$rutafichdest"

                if [[ $event -gt 0 ]]; then
                        tail -n $nuevas $rutafichorigen | sed 's/\t/\|/g' >> "$EVENTS"
                elif [[ $audit -gt 0 ]]; then
                        tail -n $nuevas $rutafichorigen | sed 's/\t/\|/g' >> "$AUDIT"
                else
                        tail -n $nuevas $rutafichorigen | sed 's/\t/\|/g'>> "$SESSIONS"
                fi
        fi
done
