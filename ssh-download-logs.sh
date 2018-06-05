#!/bin/bash

# REM - Remote
# LOC - Local
REMLOG=""
LOCRUTABASE=""
FECHALOG=`date "+[%F %H:%M]"`
TEMPORAL=""
LOGUNIFICADO="$LOCRUTABASE/unified.log"

# Array de servidores, separados por espacios
ARRAYIPS=() 

USUARIO=""
LLAVESSH=""

# ==== SCRIPT ====

for nodo in ${ARRAYIPS[*]}; do
        DEBUG="$LOCRUTABASE/script.log"

        touch "$DEBUG"
        TEMPORAL="$LOCRUTABASE/$nodo/tmp"
        mkdir -p "$TEMPORAL"

        scp -q -i $LLAVESSH $USUARIO@$nodo:$REMLOG $TEMPORAL
        rutafichremoto="$TEMPORAL/appEventos.log"

        if [ -f $rutafichremoto ]; then
                lineasremoto=`wc -l $rutafichremoto | cut -d' ' -f1`
                re='^[0-9]+$'
                if ! [[ $lineasremoto =~ $re ]] ; then
                        lineasremoto=0
                fi
                rutaloglocal="$LOCRUTABASE/$nodo.log"
                lineaslocal=0
                if [[ -f $rutaloglocal ]]; then
                        lineaslocal=`wc -l $rutaloglocal | cut -d' ' -f1`
                else
                        touch $rutaloglocal
                fi
                if [ $lineasremoto -gt $lineaslocal ]; then
                        numlineas=`expr $lineasremoto - $lineaslocal`
                        tail --lines=$numlineas $rutafichremoto >> "$rutaloglocal"
                        tail --lines=$numlineas $rutafichremoto >> "$LOGUNIFICADO"
                        echo "Añadidas $numlineas al fichero $nodo.log" >> $DEBUG
                elif [ $lineasremoto -eq $lineaslocal ]; then
                        echo "No hay nuevas lineas en el fichero de $nodo" >> $DEBUG
                else
                        echo "[ERROR] Más lineas en local que en remoto del servidor $nodo" >> $DEBUG
                fi

                # Borramos ficheros auxiliares
                rm -rf "$LOCRUTABASE/$nodo"
        else
                echo "[ERROR] No existe el fichero appEventos en $nodo" >> $DEBUG
        fi
done
