#!/bin/sh

HOST=''
USER=''
PASSWD=''
FILES='*.LOG'
DATE=`date "+%Y-%m-%d %H:%M"`

ROOTPATH=""
FTPLOG="$ROOTPATH/ftp.log"
SCRIPTLOG="$ROOTPATH/application.log"
PATHLOGS="$ROOTPATH/logs"
PATHNEWLOGS="$PATHLOGS/nuevos"

# Comprobamos si hay algún proceso de ftp que se haya quedado bloqueado para eliminarlo
zombies=`pgrep -lf "ftp -nv" | wc -l`
if [[ $zombies -ne 0 ]]; then
        pkill -f "ftp -nv"
fi

# Traemos logs nuevos del ftp
cd $PATHNEWLOGS
ftp -nv $HOST>>$FTPLOG <<END_SCRIPT
prompt
quote USER $USER
quote PASS $PASSWD
binary
mget $FILES
quit
END_SCRIPT

for elem in `ls *.TXT`; do
        echo "[$DATE] Nueva ejecución" >> $SCRIPTLOG
        if [ ! -f "$PATHLOGS/$elem" ]; then
                touch "$PATHLOGS/$elem"
                echo "[$DATE] Creado fichero $elem" >> $SCRIPTLOG
        fi
        lnuevas=`wc -l "$PATHNEWLOGS/$elem" | cut -d' ' -f1`
        lalmacenadas=`wc -l "$PATHLOGS/$elem" | cut -d' ' -f1`
        ldiff=$((lnuevas - lalmacenadas))
        echo "[$DATE] Lineas nuevas: $ldiff | Lineas almacenadas: $lalmacenadas" >> $SCRIPTLOG
        if [[ $ldiff -ne 0 ]]; then
                if [[ $ldiff -gt 0 ]]; then
                        tail -n $ldiff "$PATHNEWLOGS/$elem" >> "$PATHLOGS/$elem"
                        echo "[$DATE] Añadidas $ldiff lineas al fichero $elem" >> $SCRIPTLOG
                else
                        echo "[$DATE] [ERROR] Numero de lineas menor en log nuevo que en log ya almacenado" >> $SCRIPTLOG
                fi
        fi
        rm -rf "$PATHNEWLOGS/$elem"
done
