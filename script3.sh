#!/bin/bash

DIR_RESPALDO="$HOME/respaldo_logs"

mkdir -p "$DIR_RESPALDO" && echo "Directorio de respaldo listo en: $DIR_RESPALDO"

PREFIJO_FECHA=$(date +%Y%m%d)

CONTADOR=0

for archivo in *.log; do
    if [ -f "$archivo" ]; then
        nombre_base=$(basename "$archivo")
        
        cp "$archivo" "$DIR_RESPALDO/${PREFIJO_FECHA}_${nombre_base}" && ((CONTADOR++))
    fi
done

echo "Proceso finalizado. Se procesaron $CONTADOR archivos .log."
