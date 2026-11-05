#!/bin/bash

echo "Nombre del script: $0"
echo "Cantidad total de parametros: $#"
echo "Lista completa de parametros: $@"

if [ $# -lt 2 ]; then
    echo "Uso: $0 <origen> <destino>"
    exit 1
fi

cat archivo_inexistente.txt > error.log 2>&1

echo "Codigo de salida del comando anterior: $?"
