#!/bin/bash

echo "--- INICIANDO AUDITORIA DE USUARIOS ---"

# Leer el archivo /etc/passwd línea por línea
# IFS=: establece los dos puntos como separador de campos
while IFS=: read -r usuario pass uid gid gecos home shell; do
    
    # Clasificar según el UID
    if [ "$uid" -lt 1000 ]; then
        categoria="Usuarios de Sistema"
    else
        categoria="Usuarios Regulares"
    fi

    # Verificar si el shell de inicio de sesión está deshabilitado
    if [ "$shell" == "/bin/false" ] || [ "$shell" == "/usr/sbin/nologin" ]; then
        # Imprimir solo los que tienen el shell deshabilitado (como pide la instrucción)
        echo "[ALERTA] Usuario: $usuario | UID: $uid | Categoria: $categoria | Shell DESHABILITADA ($shell)"
    fi

done < /etc/passwd

echo "--- FIN DE LA AUDITORIA ---"
