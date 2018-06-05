#!/bin/bash

# === Constantes ===

export AZURE_STORAGE_ACCOUNT=""
export AZURE_STORAGE_ACCESS_KEY=""

export CONTAINER=""

CARPETA=""

LOG="azure-storage.log"
DATE=`date +%Y-%m-%d_%H:%M`

export BLOB="$CARPETA/$ANO/$MES/$DIA"

export HTTP_PROXY=""
export HTTPS_PROXY=""

RUTA=""
LOGSNUEVOS="$RUTA/nuevos"
PROCESADOS="$RUTA/azure"


# ====== Script ======
for folder in `azure storage blob list $CONTAINER | cut -d'/' -f1 | uniq | rev | cut -d' ' -f1 | rev`; do
        # Descarga de los ficheros nuevos
        minutos=`date +%M`
        if [ $minutos -le 10 ]; then
                ultimos=6
        else ultimos=3
        fi
        if [ ! -d "$LOGSNUEVOS/" ]; then
                mkdir $LOGSNUEVOS
        fi

        for blob in `azure storage blob list $CONTAINER | grep "$folder/" | cut -d' ' -f5 | tail -n $ultimos`; do
                azure storage blob download $CONTAINER $blob "$LOGSNUEVOS/" >> /dev/null 2> /dev/null
        done

        DATE=`date +%Y-%m-%d_%H:%M`
        for blobNuevo in `find $LOGSNUEVOS -type f | grep .log`; do
                # Comprobamos si existe la carpeta
                echo -e "\n[$DATE] [$folder] Blob nuevo: $blobNuevo" #>> $LOG
                hora=`echo $blobNuevo | cut -d'/' -f11`

                # Aqui es posible que nunca entre. Si es asi, hay que borrar
                carpetaNuevos=`echo $blobNuevo | cut -d'/' -f-11`
                if [ ! -d $carpetaNuevos ]; then
                        echo "[$DATE] [$folder] Creando directorio $carpetaNuevos" >> $LOG
                        mkdir -p $carpetaNuevos
                fi

                # Comprobamos si existe el fichero
                rutaBlob=`echo $blobNuevo | cut -d'/' -f8-`
                raiz=`echo $rutaBlob | cut -d'/' -f1`
                echo "[$DATE] [$folder] Ruta Blob: $rutaBlob" >> $LOG

                nombre=`echo $rutaBlob | cut -d'/' -f5`

                carpetaProcesados=`echo $PROCESADOS/$rutaBlob | cut -d'/' -f-10`

                if [ ! -d $carpetaProcesados ]; then
                        mkdir -p $carpetaProcesados
                        echo "[$DATE] [$folder] Creando directorio $carpetaProcesados" >> $LOG
                fi

                # Comprobamos cuantos ficheros hay procesados y sin procesar
                numFicherosProcesados=`find $carpetaProcesados | grep $nombre | grep .processed | wc -l`
                numFicherosSinProcesar=`find $carpetaProcesados | grep .log | grep $nombre | grep -v .processed | wc -l`
                echo "[$DATE] [$raiz/$hora/$nombre] Nombre fichero: $nombre" >> $LOG
                echo "[$DATE] [$raiz/$hora/$nombre] Num ficheros procesados: $numFicherosProcesados | Num ficheros no procesados: $numFicherosSinProcesar" #>> $LOG

                # Si hay mas de un fichero procesado, lo unificamos en un unico fichero
                if [ $numFicherosProcesados -gt 1 ]; then
                        echo "[$DATE] [$raiz/$hora/$nombre] Unificando ficheros procesados ..." >> $LOG
                        procesadoOriginal=`find $carpetaProcesados | grep $nombre.processed`
                        echo "[$DATE] [$raiz/$hora/$nombre] Fichero procesado original: $procesadoOriginal" #>> $LOG
                        for proc in `find $carpetaProcesados | grep $nombre | grep .processed | grep -v $procesadoOriginal`; do
                                cat $proc >> $procesadoOriginal
                                echo "[$DATE] [$raiz/$hora/$nombre] Borrando $proc ..." #>> $LOG
                                rm -f $proc
                        done
                fi

                ficheroProcesado="$carpetaProcesados/$nombre.processed"

                if [ -f $ficheroProcesado ]; then
                        lineasProcesados=`cat $ficheroProcesado | wc -l`
                else
                        lineasProcesados=0
                fi

                # Comprobamos si hay algun fichero pendiente todavia de procesar
                # Si es asi, hay que contabilizar esas lineas

                if [ $numFicherosSinProcesar -eq 1 ]; then
                        catAux=`find $carpetaProcesados | grep $nombre | grep -v processed`
                        contador=`cat $catAux | wc -l`
                        echo "[$DATE] [$raiz/$hora/$nombre] Lineas procesadas: $lineasProcesados | Lineas sin procesar: $contador" >> $LOG
                        lineasProcesados=`expr $lineasProcesados + $contador`
                elif [ $numFicherosSinProcesar -gt 1 ]; then
                        echo "[$DATE] [$raiz/$hora/$nombre] [ERROR] Más de un fichero sin procesar con el mismo nombre" >> $LOG
                        exit
                fi

                lineasNuevo=`cat $blobNuevo | wc -l`
                total=`expr $lineasNuevo - $lineasProcesados`
                echo "[$DATE] [$raiz/$hora/$nombre] Fichero nuevo: $blobNuevo | Lineas: $lineasNuevo" #>> $LOG
                echo "[$DATE] [$raiz/$hora/$nombre] Fichero procesado: $ficheroProcesado | Lineas: $lineasProcesados" #>> $LOG
                echo "[$DATE] [$raiz/$hora/$nombre] Lineas procesadas: $lineasProcesados | Lineas sin procesar: $lineasNuevo | Total : $total" >> $LOG
                if [ $total -gt 0 ]; then
                        guardado=`echo $ficheroProcesado | cut -d'.' -f-2`
                        tail -n $total $blobNuevo >> $guardado
                        echo "[$DATE] [$raiz/$hora/$nombre] Guardando $total lineas nuevas" >> $LOG
                fi
        done

        # Borramos los ficheros descargados
        rm -rf $LOGSNUEVOS/*
done