# Proyecto Final Módulo 1 Linux

## 1. Introducción y Arquitectura
Este proyecto integra los conocimientos de administración de Linux, procesamiento de texto (Shell) y programación en C. El sistema simula una herramienta de ciberseguridad que recopila telemetría del sistema en tiempo real, procesa registros de auditoría estáticos (descargados de internet) y genera un informe de seguridad en texto plano.

**Flujo del sistema:**
1. **Etapa 1:** 
    Estructura de directorios, aplicación de Principio de Mínimo Privilegio y pruebas de enlaces.

2. **Etapa 2:** 
    Descarga remota del paquete `.tar.gz`, procesamiento de logs con `awk`/`grep` y captura de métricas reales.

3. **Etapa 3:** 
    Motor en C que lee los datos, valida la integridad del archivo, calcula estadísticas y emite alertas.

4. **Etapa 4:** 
    Script orquestador (`etapa4.sh`) que ejecuta todo el flujo de forma desatendida, con tolerancia a fallos y documentación del control de procesos.


## 2. Instrucciones de Reproducción
Para ejecutar este sistema, solo necesitas tu usuario (no se requiere `sudo`) y conexión a internet (para descargar el paquete_auditoria.tar.gz  desde GitHub).

1. Abre la terminal en la raíz de este repositorio (donde quieras que se ejecute).
2. Otorga permisos de ejecución a los scripts: 
        chmod +x etapa*.sh  --> chmod +x etapa1.sh
                                chmod +x etapa2.sh
                                chmod +x etapa3.sh
                                chmod +x etapa4.sh
3. Ejecutar el script etapa4.sh hara que se ejecuten los demas mientras esten en el mismo dorectorio
        ./etapa4.sh


## 3. Decisiones de Diseño y Desglose Técnico

**Etapa 1: Entorno y Permisos**

    set -e: Descubrí que es una herramienta excelente para manejar errores. Hace que el script se detenga inmediatamente si algún comando falla, evitando que se sigan ejecutando pasos con datos corruptos o mostrando falsos positivos de éxito.

    mkdir -p sec_guard/{...}: Usé el flag -p para crear directorios padre automáticamente y evitar errores si la carpeta ya existe. Usé las llaves {} (Brace Expansion) para crear todas las subcarpetas de golpe, demostrando un manejo eficiente de la terminal.

    chmod -R 700: Apliqué el Principio de Mínimo Privilegio. El 7 le da control total (lectura, escritura, ejecución) solo al dueño, y los 00 le quitan todo acceso al grupo y a otros usuarios. La -R aplica esto recursivamente a todo el árbol.

    ln -s y ln: Usé ln -s para crear un acceso directo (enlace simbólico) hacia la carpeta de pruebas. Luego usé ln (sin -s) para crear un enlace duro (hardlink.txt), demostrando que ambos archivos comparten el mismo bloque físico de datos en el disco.

    stat archivo > link_record.txt: En lugar de usar ls -l que da un resumen básico, usé stat porque necesitaba extraer los metadatos exactos que pide la rúbrica: los permisos en formato octal, el número de inodo (que demuestra el enlace duro) y las marcas de tiempo exactas (Access, Modify, Change).


**Etapa 2: Captura y Procesamiento

    curl -sSL -f -o: Para descargar el paquete de GitHub de forma automática. La -s silencia el progreso, -S muestra errores, -L sigue redirecciones y -f (fail) es crucial: hace que falle si el servidor devuelve un 404, evitando que descarguemos una página HTML basura en lugar del archivo .tar.gz.

    tar -tzf > /dev/null: Antes de extraer, valido la integridad estructural del paquete. Si está corrupto, el script aborta de inmediato.

    awk para SSH (sshd_config): Usé awk porque permite lógica condicional. La instrucción sub() quita los comentarios # de las líneas HostKey. El comando next asegura que una línea procesada no se imprima dos veces, y al final se filtran los comentarios y líneas vacías.

    awk para Redes (net_traffic.log): En lugar de usar sed (que se enreda con los puntos de las IPs), usé awk con la función split(..., "."). Esto separa limpiamente los 4 octetos de la IP del puerto, sin importar cuántos dígitos tenga cada uno.

    find -perm /022: Para auditar permisos, busqué archivos regulares (-type f) que tuvieran permisos de escritura para el grupo (020) o para otros (002). La diagonal / significa "cualquiera de estos".

    wc -l < "$RAW": El operador < pasa el archivo directo a wc sin que tenga que abrirlo por nombre, permitiendo que el comando solo devuelva el número entero de líneas para la cabecera.


**Etapa 3: Motor en C (sec_engine.c)

    gcc -Wall -Wextra: Compilé con banderas de rigor. Si hay variables no inicializadas o fallos de sintaxis, el compilador falla y el script Bash se detiene, previniendo ejecutar un binario defectuoso.

    malloc y free: Usé memoria dinámica (typedef struct) porque el archivo .txt varía en cantidad de registros. Reservo memoria exacta tras leer la cabecera. Si hay cualquier error (archivo incompleto, categoría inválida), el código cierra el archivo con fclose y libera la memoria con free antes de salir.

    Validación aritmética: Para evitar división por cero, antes de calcular el promedio verifico que cantidad > 0. Además, el mínimo y máximo se inicializan con la primera medición de esa categoría, no con 0, para no viciar los datos.


**Etapa 4: Orquestación y Procesos

    Limpieza preventiva (rm -f): Antes de arrancar, el script elimina el informe anterior. Si el flujo falla a la mitad (por ejemplo, fallo de red), no verás un informe viejo haciéndose pasar por nuevo.

    Control de Procesos: Usé sleep 300 & (el & lo manda a segundo plano). Extraje su PID y le envié señales del sistema operativo documentadas en admin_process.txt:

        kill -STOP: Pausa el proceso (SIGSTOP).

        kill -CONT: Reanuda el proceso (SIGCONT).

        kill -TERM: Termina el proceso de forma amigable (SIGTERM).


##4. Respuestas a las Preguntas de Reflexión
**Etapa 1

    ¿Por qué los permisos de directorio difieren de los de archivo? Porque en un directorio, el bit de ejecución (x) permite atravesarlo (hacer cd), y el de escritura (w) permite crear/borrar archivos dentro. En un archivo, x es para ejecutarlo como programa, y w para modificar su contenido.

    Diferencia entre original y enlace duro: Físicamente son idénticos. Comparten el mismo número de inodo y los mismos bloques de datos. Si borras el original, el enlace duro sigue funcionando y conservando la información.

    Utilidad del enlace simbólico: Sirve como un "acceso directo" para no escribir rutas largas. Es ideal para apuntar a versiones de librerías o enlazar carpetas sin duplicar datos.

    Metadatos y cambios: El mtime indica cuándo cambió el contenido, el ctime cuándo cambiaron los permisos/dueño, y el atime cuándo fue leído por última vez. Sirven para auditar alteraciones.

**Etapa 2

    Transformación de datos: Requiere limpiar el texto. Por ejemplo, df -h devuelve un 45%; usando tr -d '%' y awk se convierte en un entero (45) que C puede procesar.

    Valor cero vs captura fallida: El 0 es un dato real y válido (0% de uso de disco). Una captura fallida significa que la utilería no pudo ejecutarse y debe reportarse como error, nunca como cero.

    Comprobación de cabecera: El script normalizador cuenta las líneas reales con wc -l y lo escribe en la cabecera. C luego vuelve a contar y si no coinciden, aborta.

    Orden en Sed/Awk: Primero se habilitan las directivas (quitando el #) y al final se eliminan los comentarios sobrantes. Si se hace al revés, perderíamos las directivas que acabábamos de habilitar.

    Aislar IP y Puerto: Usé la función split() de awk con el punto como delimitador, separando los 4 octetos de la IP del puerto sin importar la longitud de los mismos.

**Etapa 3

    Medición vs Resumen: La medición es el dato crudo de una línea (ej. 80% disco). El resumen es la agrupación matemática (promedio, alertas). Usar structs separadas hace el código ordenado.

    Evitar división por cero: Con el condicional if (cantidad > 0) antes de calcular el promedio. El mínimo y máximo se inicializan con la primera lectura válida, no con 0, para no falsear los resultados.

    Liberación de recursos: Si falla una lectura, se usa free(datos) para liberar el malloc y fclose(entrada) para cerrar el archivo, evitando fugas de memoria.

**Etapa 4

    Control de flujo en Shell: El script usa set -e y verifica los códigos de retorno. Si C devuelve un error, el script se detiene de inmediato y no entrega un informe corrupto.

    Distinguir informe nuevo: La limpieza preventiva borra el informe viejo al inicio. Si el script falla, no habrá ningún informe; si existe, es porque el flujo terminó al 100%.

    Evidencia de automatización: El uso de curl (descarga remota), gcc (compilación) y la captura en vivo de telemetria_raw.log demuestran que el sistema funciona sin intervención humana.



Pruebas
1. Demostrar que el script orquestador (ejecutar.sh) valida la integridad de los insumos antes de intentar procesarlos y no continúa a ciegas si un archivo base está dañado.
 
Se alteró la URL para descargar un HTML. El script abortó lanzando "El archivo descargado esta corrupto o no es un .tar.gz valido". Ya realizando pruebas para consumir o en este caso descargar desde un repositorio en github al modificar la ruta en lo mas minimo el programa se detiene y avisa que debes revisar el script donde se esta consumiento o el mismo archivo como si estuviera danado. otra prueba fue cambiar la URL para hacer que quede htps en lugar de https lo cual representa un error y si marca que no puede porque no es compatible

curl: (1) Protocol "htps" not supported
Error critico: No se pudo descargar el paquete desde htps://raw.githubusercontent.com/OrtizAdolfo/Introuccion_Bash_DSSI_2027/21d99859b6e317d3d39158b9caac7f67b5982db1/paquete_auditoria.tar.gz

"Error critico: El archivo descargado esta corrupto o no es un .tar.gz valido."


2. Demostrar que el analizador en C (sec_engine.c) no asume entradas ciegas, previene desbordamientos de memoria (buffer overflow) y detecta archivos incompletos o manipulados. 
Se altero la cabecera del .txt para decir 15 registros cuando solo había 9. El binario de C abortó lanzando "Error: Registros faltantes".

con los comando hicimos una pequena manipulacion al archivo ya que modifica la cabecera (línea 2) para decir que hay 15 registros
./etapa4.sh

sed -i '2s/.*/AuditoriaCursoC 15/' sec_guard/preparados/mediciones_sec.txt

./sec_guard/fuentes/sec_engine sec_guard/preparados/mediciones_sec.txt sec_guard/resultados/test2.txt

Al ejecutar el binario `./sec_guard/fuentes/sec_engine`, el programa detectó la discrepancia y abortó arrojando: `"Error: Registros faltantes. Declarados: 15, Leidos: 9"`. Previene el desbordamiento de memoria al no asumir entradas ciegas.


3. Comprobar la resiliencia aritmética del motor en C frente a conjuntos de datos con observaciones nulas.
Se ingresó un archivo con 0 registros y otro sin la categoría PERMISOS. El programa C no se dividió por cero y escribió "Sin datos" correctamente. Se crearon dos archivos de prueba: uno declarando 0 registros, y otro omitiendo la categoría `PERMISOS`.

# Caso: Archivo declarando 0 registros
echo "AuditoriaCursoC 0" > sec_guard/preparados/test_cero.txt
./sec_guard/fuentes/sec_engine sec_guard/preparados/test_cero.txt sec_guard/resultados/test_cero_out.txt
cat sec_guard/resultados/test_cero_out.txt

Salida:
Informe generado exitosamente en: sec_guard/resultados/test_cero_out.txt
INFORME DE MONITOREO
Etiqueta: AuditoriaCursoC
Registros: 0

Categoria DISCO
• Sin datos

Categoria PROCESOS
• Sin datos

Categoria PERMISOS
• Sin datos

Observaciones que cumplen condiciones de alerta: 0.
Umbrales utilizados con fines didácticos.

# Caso: Archivo sin la categoría PERMISOS
printf "AuditoriaCursoC 2\nDISCO 50\nPROCESOS 15\n" > sec_guard/preparados/test_sin_permisos.txt
./sec_guard/fuentes/sec_engine sec_guard/preparados/test_sin_permisos.txt sec_guard/resultados/test_sin_permisos_out.txt
cat sec_guard/resultados/test_sin_permisos_out.txt # Muestra "Sin datos" solo en PERMISOS.

Salida:
Informe generado exitosamente en: sec_guard/resultados/test_sin_permisos_out.txt
INFORME DE MONITOREO
Etiqueta: AuditoriaCursoC
Registros: 2

Categoria DISCO
• Cantidad: 1
• Suma: 50
• Mínimo: 50
• Máximo: 50
• Promedio: 50.00
• Alertas: 0

Categoria PROCESOS
• Cantidad: 1
• Suma: 15
• Mínimo: 15
• Máximo: 15
• Promedio: 15.00
• Alertas: 0

Categoria PERMISOS
• Sin datos

Observaciones que cumplen condiciones de alerta: 0.
Umbrales utilizados con fines didácticos.

# Caso: Archivo con valores en el límite exacto (deben generar alertas)
Se introdujo un archivo con los valores exactos de los umbrales (`DISCO 80`, `PROCESOS 30`, `PERMISOS 1`). El programa registró correctamente 3 alertas. Esto comprueba que las condiciones lógicas (`>=` para disco y procesos, y `> 0` para permisos) están bien implementadas.

printf "AuditoriaCursoC 3\nDISCO 80\nPROCESOS 30\nPERMISOS 1\n" > sec_guard/preparados/test_limites.txt
./sec_guard/fuentes/sec_engine sec_guard/preparados/test_limites.txt sec_guard/resultados/test_limites_out.txt
cat sec_guard/resultados/test_limites_out.txt

Salida:
Informe generado exitosamente en: sec_guard/resultados/test_limites_out.txt
INFORME DE MONITOREO
Etiqueta: AuditoriaCursoC
Registros: 3

Categoria DISCO
• Cantidad: 1
• Suma: 80
• Mínimo: 80
• Máximo: 80
• Promedio: 80.00
• Alertas: 1

Categoria PROCESOS
• Cantidad: 1
• Suma: 30
• Mínimo: 30
• Máximo: 30
• Promedio: 30.00
• Alertas: 1

Categoria PERMISOS
• Cantidad: 1
• Suma: 1
• Mínimo: 1
• Máximo: 1
• Promedio: 1.00
• Alertas: 1

Observaciones que cumplen condiciones de alerta: 3.
Umbrales utilizados con fines didácticos.

# Caso: Archivo con valor incorrecto (DISCO mayor a 100)
Se ingresó un valor de `DISCO 150` (fuera del rango 0-100) y se intentó ejecutar el motor con un archivo fantasma.
Para el valor incorrecto, el programa rechazó la entrada con: `"Error: Categoria desconocida o valor fuera de rango"`. Para el archivo inexistente, arrojó: `"Error: No se pudo abrir el archivo de entrada"`. En ningún caso se generó un informe corrupto.
printf "AuditoriaCursoC 1\nDISCO 150\n" > sec_guard/preparados/test_incorrecto.txt
./sec_guard/fuentes/sec_engine sec_guard/preparados/test_incorrecto.txt sec_guard/resultados/test_incorrecto_out.txt

Salida:
Error: Categoria desconocida o valor fuera de rango (DISCO 150).

# Caso: Archivo inexistente
./sec_guard/fuentes/sec_engine sec_guard/preparados/archivo_fantasma.txt sec_guard/resultados/test_inexistente.txt

Salida:
Error: No se pudo abrir el archivo de entrada sec_guard/preparados/archivo_fantasma.txt

El analizador en C no se inmuto por las divisiones por cero. En ambos casos, el informe final imprimió correctamente la leyenda `"Sin datos"` en las categorías que no tenian nada de observaciones.


4. Comprobar que el script orquestador elimina resultados previos y no entrega un informe viejo cuando ocurre un error en una fase intermedia.
Se forzó un fallo en la red. Se forzó un fallo a mitad del flujo (cambiando la URL a una inválida). Gracias a la limpieza de etapa4.sh, el archivo informe_seguridad.txt no existió al final, demostrando que no se entregan informes obsoletos.

# 1. Genera un informe válido
./etapa4.sh
ls -l sec_guard/resultados/informe_seguridad.txt 

Salida:
-rw-rw-r-- 1 vboxuser vboxuser 503 Nov 13 19:09 sec_guard/resultados/informe_seguridad.txt


# 2. Se vuelve a romper la URL para forzar el fallo
cp etapa2.sh etapa2.sh.bak
sed -i 's|https://raw.githubusercontent.com/.*|https://github.com/error404.tar.gz|' etapa2.sh
./etapa4.sh

Salida:
INICIANDO DE ETAPA 4

->Asegurando limpieza de resultados previos...

>>> EJECUTANDO ETAPA 1...
INICIO DE LA ETAPA 1
->Estructura de directorios creada.
.
├── capturas
├── evidencias
├── fuentes
├── preparados
├── resultados
└── scripts

7 directories, 0 files
->Permisos restrictivos (RWX) solo a quien le pertenecen los directorios.
->Documento permissions.txt generado.
->Enlace simbolico 'enlace_pruebas' creado.
->Archivos de prueba, enlace duro y renombrado configurados.
->Registrados en evidencias/link_record.txt
->Estructura con nuevos archivos de metadatos y comprobacion
.
├── capturas
├── enlace_pruebas -> evidencias/pruebas
├── evidencias
│   ├── link_record.txt
│   ├── permissions.txt
│   └── pruebas
│       ├── hardlink.txt
│       └── prueba_doc_renombrado.txt
├── fuentes
├── preparados
├── resultados
└── scripts

9 directories, 4 files
ETAPA 1 COMPLETADA

>>> EJECUTANDO ETAPA 2...
INICIO DE LA ETAPA 2
Directorio actual: /home/vboxuser/Downloads/ProyectoFinalLinux
->Descargando paquete de auditoria...
./etapa2.sh: line 117: syntax error near unexpected token `('


# 4. Se comprueba que el informe viejo ya no está
ls -l sec_guard/resultados/informe_seguridad.txt 

Salida:
ls: cannot access 'sec_guard/resultados/informe_seguridad.txt': No such file or directory

Gracias a la instrucción `rm -f` al inicio del orquestador, el informe de la ejecución anterior fue eliminado. Al fallar el proceso, no se encontró ningún archivo `informe_seguridad.txt`, demostrando que el sistema nunca entrega resultados viejos como si fueran nuevos.


5. Demostrar que el orquestador (ejecutar.sh) detecta errores del compilador, aborta la ejecución de inmediato y no ejecuta un binario previamente compilado que haya quedado en el directorio fuentes/.
Se borró un punto y coma en sec_engine.c. GCC falló y el script etapa4.sh se detuvo en la Etapa 3, impidiendo ejecutar un binario viejo.

# 1. Respaldamos el script
cp etapa3.sh etapa3.sh.bak

# 2. Rompemos el código ya que se quita el punto y coma de un return 0;
sed -i 's/return 0;/return 0/' etapa3.sh

# 3. Se ejecuta
./etapa4.sh

Salida:
>>> EJECUTANDO ETAPA 3...
INICIO DE LA ETAPA 3
-> Generando el codigo fuente (sec_engine.c)...
-> Codigo fuente generado correctamente.
-> Compilando sec_engine.c con banderas de rigor...
sec_guard/fuentes/sec_engine.c: In function ‘validar_categoria’:
sec_guard/fuentes/sec_engine.c:24:13: error: expected ‘;’ before ‘}’ token
   24 |     return 0
      |             ^
      |             ;
   25 | }
      | ~            
sec_guard/fuentes/sec_engine.c: In function ‘main’:
sec_guard/fuentes/sec_engine.c:166:13: error: expected ‘;’ before ‘}’ token
  166 |     return 0
      |             ^
      |             ;
  167 | }
      | ~    

El comando `gcc` falló. Gracias al uso de `set -e`, el orquestador abortó la ejecución inmediatamente en la Etapa 3, impidiendo que se ejecutara un binario previamente compilado que hubiera quedado en el directorio.
