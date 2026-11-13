#!/bin/bash
set -e

echo "INICIO DE LA ETAPA 2"

# Verificar que estamos en la carpeta correcta
if [ ! -d "sec_guard" ]; then
    echo "Error: No se encuentra el directorio sec_guard. Ejecuta este script desde la raiz del proyecto."
    exit 1
fi

# 1. DESCARGA, VALIDACION Y DESEMPAQUETADO
echo "-> Descargando paquete de auditoria desde GitHub..."

# URL apuntando al archivo RAW binario
URL_PAQUETE="https://raw.githubusercontent.com/OrtizAdolfo/Introuccion_Bash_DSSI_2027/21d99859b6e317d3d39158b9caac7f67b5982db1/paquete_auditoria.tar.gz"
RUTA_PAQUETE="sec_guard/capturas/estaticos/paquete_auditoria.tar.gz"

mkdir -p sec_guard/capturas/estaticos

# Descargar con manejo de errores (-s silencioso, -S errores, -L redirecciones, -f fallar en 404)
if ! curl -sSL -f -o "$RUTA_PAQUETE" "$URL_PAQUETE"; then
    echo "Error critico: No se pudo descargar el paquete desde $URL_PAQUETE"
    exit 1
fi

# Validar la integridad estructural del archivo
if ! tar -tzf "$RUTA_PAQUETE" > /dev/null 2>&1; then
    echo "Error critico: El archivo descargado esta corrupto o no es un .tar.gz valido."
    exit 1
fi

# Extraer el contenido
tar -xzf "$RUTA_PAQUETE" -C sec_guard/capturas/estaticos/

# Validar que se extrajeron los 3 archivos esperados
CANT_ARCHIVOS=$(find sec_guard/capturas/estaticos/ -maxdepth 1 -type f ! -name "*.tar.gz" | wc -l)
if [ "$CANT_ARCHIVOS" -lt 3 ]; then
    echo "Error: No se extrajeron los 3 archivos esperados."
    exit 1
fi
echo "-> Paquete descargado y extraido correctamente."

# 2. DEPURACION DE CONFIGURACION (SSHD) CON AWK
echo "-> Procesando sshd_config..."
awk '
/^[[:space:]]*#?[[:space:]]*HostKey/ { sub(/^[[:space:]]*#?[[:space:]]*/, ""); print; next }
/^[[:space:]]*#?[[:space:]]*Port/ { print "Port 8080"; next }
/^[[:space:]]*#/ { next }
/^[[:space:]]*$/ { next }
{ print }
' sec_guard/capturas/estaticos/sshd_config > sec_guard/preparados/sshd_activo.txt

# 3. EXTRACCION DE USUARIOS CREADOS
echo "-> Extrayendo usuarios de secure.log..."
grep "new user" sec_guard/capturas/estaticos/secure.log | \
awk '{printf "Usuario: %s | UID: %s | GID: %s\n", $8, $10, $12}' \
> sec_guard/preparados/usuarios_creados.txt

# 4. AISLAR CONEXIONES SYN
echo "-> Extrayendo conexiones TCP (SYN) de net_traffic.log..."
awk '/Flags \[S\]/ { gsub(/:/, "", $4); split($2, src, "."); split($4, dst, "."); print "IP Origen: " src[1]"."src[2]"."src[3]"."src[4] ", Puerto Origen: " src[5] " -> IP Destino: " dst[1]"."dst[2]"."dst[3]"."dst[4] ", Puerto Destino: " dst[5] }' sec_guard/capturas/estaticos/net_traffic.log > sec_guard/preparados/conexiones_syn.txt

# 5. CREACION DEL SCRIPT DE CAPTURA (capturar.sh)
echo "-> Creando scripts/capturar.sh..."
cat > sec_guard/scripts/capturar.sh << 'EOF'
#!/bin/bash
RAW_FILE="../capturas/telemetria_raw.log"
mkdir -p ../capturas
FECHA=$(date +"%Y-%m-%d %H:%M:%S")

DISCO_VAL=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
PROCESOS_VAL=$(ps -u $USER --no-headers | wc -l)
PERMISOS_VAL=$(find .. -type f -perm /022 2>/dev/null | wc -l)

echo "$FECHA | DISCO | $DISCO_VAL" >> $RAW_FILE
echo "$FECHA | PROCESOS | $PROCESOS_VAL" >> $RAW_FILE
echo "$FECHA | PERMISOS | $PERMISOS_VAL" >> $RAW_FILE
EOF
chmod +x sec_guard/scripts/capturar.sh

# 6. EJECUTAR CAPTURAS Y NORMALIZAR
echo "-> Ejecutando capturas (3 veces)..."
cd sec_guard/scripts
rm -f ../capturas/telemetria_raw.log

./capturar.sh
sleep 1
./capturar.sh
sleep 1
./capturar.sh

echo "-> Generando archivo normalizado..."
cat > normalizar.sh << 'EOF'
#!/bin/bash
RAW="../capturas/telemetria_raw.log"
OUT="../preparados/mediciones_sec.txt"
TOTAL=$(wc -l < "$RAW")
echo "AuditoriaCursoC $TOTAL" > "$OUT"
awk -F '|' '{gsub(/ /, "", $2); gsub(/ /, "", $3); print $2, $3}' "$RAW" >> "$OUT"
EOF
chmod +x normalizar.sh

./normalizar.sh
cd ../..

echo "ETAPA 2 COMPLETADA CON EXITO"
