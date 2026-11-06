#!/bin/bash

# Verificar que se haya proporcionado al menos un argumento
if [ $# -eq 0 ]; then
    echo "Error: Debes proporcionar una ruta como primer parametro."
    echo "Uso: $0 <ruta_archivo_o_directorio>"
    exit 1
fi

# Guardar la ruta en una variable
RUTA=$1

# Evaluar si la ruta existe 
if [ -e "$RUTA" ]; then
    echo "La ruta '$RUTA' existe."
    
    # Evaluar si es un archivo regular o un directorio
    if [ -f "$RUTA" ]; then
        echo "Es un archivo regular."
    elif [ -d "$RUTA" ]; then
        echo "Es un directorio."
    else
        echo "Es otro tipo de archivo (por ejemplo, un enlace)."
    fi
    
    # Evaluar permisos de lectura 
    if [ -r "$RUTA" ]; then
        echo "Tiene permisos de lectura: SI."
    else
        echo "Tiene permisos de lectura: NO."
    fi
    
    # Evaluar permisos de escritura 
    if [ -w "$RUTA" ]; then
        echo "Tiene permisos de escritura: SI."
    else
        echo "Tiene permisos de escritura: NO."
    fi

else
    echo "Error: La ruta '$RUTA' no existe."
    exit 1
fi
