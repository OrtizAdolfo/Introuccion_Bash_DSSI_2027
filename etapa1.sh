#!/bin/bash
set -e
echo "INICIO DE LA ETAPA 1"

# 1. Crear la estructura de directorios
# Eliminamos una posible coincidencia con una ejecucion anterior
rm -rf sec_guard/

# Con -p para que no marque error si ya existen
mkdir -p sec_guard/{capturas,preparados,fuentes,scripts,resultados,evidencias}
chmod 700 sec_guard/
cd sec_guard
echo "-> Estructura de directorios creada."
echo "$(tree)"
# 2. Asignar permisos restrictivos
# Aplicamos 700 (lectura, escritura, ejecucion) solo al dueño
chmod -R 700 capturas preparados fuentes scripts resultados evidencias
echo "-> Permisos restrictivos aplicados a directorios."

# 3. Documentar los permisos en evidencias/permissions.txt
cat > evidencias/permissions.txt << 'EOF'
Permisos aplicados en sec_guard (Principio de Minimo Privilegio):
- Directorios y Scripts (700): Acceso total y exclusivo unicamente para el propietario.
- Archivos de datos (600): Lectura y escritura exclusiva para el propietario.
Motivo: Proteger la telemetria y los registros de accesos no autorizados.
EOF
chmod 600 evidencias/permissions.txt
echo "-> Documento permissions.txt generado."

# 4. Crear directorio de pruebas y enlace simbolico
mkdir -p evidencias/pruebas
chmod 700 evidencias/pruebas/
# Eliminamos el enlace si ya existia para evitar error en ejecuciones repetidas
rm -f enlace_pruebas
ln -s evidencias/pruebas enlace_pruebas
echo "-> Enlace simbolico 'enlace_pruebas' creado."

# 5. Generar archivo de prueba, enlace duro y renombrar
cd evidencias/pruebas
# Limpiamos si ya existian archivos de pruebas anteriores
rm -f prueba_doc_renombrado.txt hardlink.txt prueba_doc.txt

touch prueba_doc.txt
# Agregamos informacion del sistema (fecha)
date > prueba_doc.txt

# Crear enlace duro
ln prueba_doc.txt hardlink.txt

# Renombrar el original
mv prueba_doc.txt prueba_doc_renombrado.txt

# Cambiar permisos a los archivos (sin ejecucion)
chmod 600 prueba_doc_renombrado.txt hardlink.txt

# 6. Registrar los metadatos en link_record.txt
cd ../..
# Usamos stat para obtener inodo, permisos, dueño, tamaño y tiempos
stat evidencias/pruebas/prueba_doc_renombrado.txt evidencias/pruebas/hardlink.txt > evidencias/link_record.txt
chmod 600 evidencias/link_record.txt

echo "$(tree)"
echo "ETAPA 1 COMPLETADA CON EXITO"
