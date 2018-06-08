#!/bin/bash

# === Variables ===

export AZURE_STORAGE_ACCOUNT=""
export AZURE_STORAGE_ACCESS_KEY=""

export CONTAINER=""

CARPETA=""

LOG="azure-cli-v1.log"
DATE=`date +%Y-%m-%d_%H:%M`

export BLOB="$CARPETA/$ANO/$MES/$DIA"

export HTTP_PROXY=""
export HTTPS_PROXY=""

RUTA=""
PATHNEWLOGS="$RUTA/newlogs"
PATHPROCESSEDLOGS="$RUTA/processed"


# ====== Script ======
for folder in `azure storage blob list $CONTAINER | cut -d'/' -f1 | uniq | rev | cut -d' ' -f1 | rev`; do
        # Downloading logs
        minutes=`date +%M`
        if [ $minutes -le 10 ]; then
                lastmins=6
        else lastmins=3
        fi
        if [ ! -d "$PATHNEWLOGS/" ]; then
                mkdir $PATHNEWLOGS
        fi

        for blob in `azure storage blob list $CONTAINER | grep "$folder/" | cut -d' ' -f5 | tail -n $lastmins`; do
                azure storage blob download $CONTAINER $blob "$PATHNEWLOGS/" >> /dev/null 2> /dev/null
        done

        DATE=`date +%Y-%m-%d_%H:%M`
        for newblob in `find $PATHNEWLOGS -type f | grep .log`; do
                # Check if the folder exists
                echo -e "\n[$DATE] [$folder] New blob: $newblob" 
                hora=`echo $newblob | cut -d'/' -f11`

                # Maybe here won't access because of the code we have before. Just a second check
                newfolder=`echo $newblob | cut -d'/' -f-11`
                if [ ! -d $newfolder ]; then
                        echo "[$DATE] [$folder] Creating folder $newfolder" >> $LOG
                        mkdir -p $newfolder
                fi

                # Comprobamos si existe el fichero
                blobpath=`echo $newblob | cut -d'/' -f8-`
                root=`echo $blobpath | cut -d'/' -f1`
                echo "[$DATE] [$folder] Blob path: $blobpath" >> $LOG

                name=`echo $blobpath | cut -d'/' -f5`

                processedfolder=`echo $PATHPROCESSEDLOGS/$blobpath | cut -d'/' -f-10`

                if [ ! -d $processedfolder ]; then
                        mkdir -p $processedfolder
                        echo "[$DATE] [$folder] Creating folder $processedfolder" >> $LOG
                fi

                # Checking how many files are processed and how many are unprocessed
                totalprocessedfiles=`find $processedfolder | grep $name | grep .processed | wc -l`
                totalunprocessedfiles=`find $processedfolder | grep .log | grep $name | grep -v .processed | wc -l`
                echo "[$DATE] [$root/$hora/$name] File name: $name" >> $LOG
                echo "[$DATE] [$root/$hora/$name] # Processed files: $totalprocessedfiles | # Unprocessed files: $totalunprocessedfiles"

                # If there is more than one processed files, we'll unified them
                if [ $totalprocessedfiles -gt 1 ]; then
                        echo "[$DATE] [$root/$hora/$name] Unifying processed files..." >> $LOG
                        originalprocessed=`find $processedfolder | grep $name.processed`
                        for proc in `find $processedfolder | grep $name | grep .processed | grep -v $originalprocessed`; do
                                cat $proc >> $originalprocessed
                                echo "[$DATE] [$root/$hora/$name] Deleting $proc ..." 
                                rm -f $proc
                        done
                fi

                processedfile="$processedfolder/$name.processed"

                if [ -f $processedfile ]; then
                        linesprocessed=`cat $processedfile | wc -l`
                else
                        linesprocessed=0
                fi

                # Checking if there is still some files unprocessed
                if [ $totalunprocessedfiles -eq 1 ]; then
                        unprocessedlines=`find $processedfolder | grep $name | grep -v processed`
                        totalunprocessedlines=`cat $unprocessedlines | wc -l`
                        echo "[$DATE] [$root/$hora/$name] Processed lines: $linesprocessed | Unprocessed lines: $totalunprocessedlines" >> $LOG
                        linesprocessed=$((linesprocessed + totalunprocessedlines))
                elif [ $totalunprocessedfiles -gt 1 ]; then
                        echo "[$DATE] [$root/$hora/$name] [ERROR] More than one file with same name. Exiting..." >> $LOG
                        exit 1
                fi

                linesnew=`cat $newblob | wc -l`
                total=`expr $linesnew - $linesprocessed`
                echo "[$DATE] [$root/$hora/$name] Processed lines: $linesprocessed | Unprocessed lines: $totalunprocessedlines | Total : $total" >> $LOG
                if [ $total -gt 0 ]; then
                        storing=`echo $processedfile | cut -d'.' -f-2`
                        tail -n $total $newblob >> $storing
                        echo "[$DATE] [$root/$hora/$name] Stored $total new lines" >> $LOG
                fi
        done

        # Delete all unnecessary files
        rm -rf $PATHNEWLOGS/*
done