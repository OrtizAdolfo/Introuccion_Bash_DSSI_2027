#!/bin/bash
set -e

echo "INICIO DE LA ETAPA 4"

# Verificar que los 3 scripts existan en el directorio actual
for script in etapa1.sh etapa2.sh etapa3.sh; do
    if [ ! -f "$script" ]; then
        echo "Error critico: No se encuentra el archivo $script en el directorio actual."
        exit 1
    fi
    chmod +x "$script"
done

# 1. LIMPIEZA PREVENTIVA EXPLICITA
echo -e "\n->Asegurando limpieza de resultados previos..."
# Nos aseguramos de que no quede un informe viejo
rm -f sec_guard/resultados/informe_seguridad.txt

# 2. EJECUCION SECUENCIAL DE LAS ETAPAS
echo -e "\n>>> EJECUTANDO ETAPA 1..."
./etapa1.sh

echo -e "\n>>> EJECUTANDO ETAPA 2..."
./etapa2.sh

echo -e "\n>>> EJECUTANDO ETAPA 3..."
./etapa3.sh

# 3. VALIDACION DEL PRODUCTO FINAL
echo -e "\n->Validando que el informe final se haya generado correctamente..."
RUTA_INFORME="sec_guard/resultados/informe_seguridad.txt"

if [ -s "$RUTA_INFORME" ]; then
    echo "-> Validacion exitosa: El informe existe y contiene datos."
else
    echo "Error critico: El informe no existe o esta vacio. El flujo fallo."
    exit 1
fi

# 4. ADMINISTRACION DE PROCESOS PROPIOS
echo -e "\n->Iniciando practica de administracion de procesos..."
DOC_PROC="sec_guard/evidencias/pruebas/admin_process.txt"

echo "REGISTRO DE ADMINISTRACION DE PROCESOS" > "$DOC_PROC"
echo "Fecha de ejecucion: $(date)" >> "$DOC_PROC"
echo "Usuario: $USER" >> "$DOC_PROC"

# Iniciar un proceso (sleep) en segundo plano
sleep 300 &
PID_PRUEBA=$!

echo -e "\n[PASO 1] Proceso iniciado en segundo plano." >> "$DOC_PROC"
echo "Comando: sleep 300" >> "$DOC_PROC"
echo "PID asignado: $PID_PRUEBA" >> "$DOC_PROC"
ps -p $PID_PRUEBA -o pid,user,stat,cmd >> "$DOC_PROC"

# Suspender (SIGSTOP)
kill -STOP $PID_PRUEBA
echo -e "\n[PASO 2] Proceso suspendido (SIGSTOP)." >> "$DOC_PROC"
echo "El estado (STAT) debe mostrar una 'T' (Stopped)." >> "$DOC_PROC"
ps -p $PID_PRUEBA -o pid,user,stat,cmd >> "$DOC_PROC"

# Reanudar (SIGCONT)
kill -CONT $PID_PRUEBA
echo -e "\n[PASO 3] Proceso reanudado (SIGCONT)." >> "$DOC_PROC"
echo "El estado (STAT) debe volver a 'S' (Sleeping)." >> "$DOC_PROC"
ps -p $PID_PRUEBA -o pid,user,stat,cmd >> "$DOC_PROC"

# Terminar (SIGTERM)
kill -TERM $PID_PRUEBA
echo -e "\n[PASO 4] Proceso terminado controladamente (SIGTERM)." >> "$DOC_PROC"
echo "El proceso ha sido eliminado del sistema." >> "$DOC_PROC"

echo "-> Evidencia guardada en: $DOC_PROC"

echo "   FLUJO COMPLETO FINALIZADO CON EXITO            "
echo "Puedes revisar el informe en: $RUTA_INFORME"
