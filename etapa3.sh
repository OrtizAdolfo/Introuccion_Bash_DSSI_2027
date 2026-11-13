#!/bin/bash
set -e

echo "INICIO DE LA ETAPA 3"

if [ ! -d "sec_guard" ]; then
    echo "Error: No se encuentra el directorio sec_guard."
    exit 1
fi

INPUT_FILE="sec_guard/preparados/mediciones_sec.txt"
OUTPUT_FILE="sec_guard/resultados/informe_seguridad.txt"
CODIGO_C="sec_guard/fuentes/sec_engine.c"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error critico: No existe el archivo de entrada $INPUT_FILE"
    exit 1
fi

echo "-> Generando el codigo fuente (sec_engine.c)..."

cat > "$CODIGO_C" << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { char categoria[15]; int valor; } Medicion;
typedef struct { int cantidad, suma, minimo, maximo, alertas, tiene_datos; float promedio; } ResumenCategoria;

int validar_categoria(const char *cat, int valor) {
    if (strcmp(cat, "DISCO") == 0) return (valor >= 0 && valor <= 100);
    if (strcmp(cat, "PROCESOS") == 0) return (valor >= 0 && valor <= 2000);
    if (strcmp(cat, "PERMISOS") == 0) return (valor >= 0 && valor <= 200);
    return 0;
}

void escribir_categoria(FILE *archivo, const char *nombre, ResumenCategoria *res) {
    fprintf(archivo, "Categoria %s\n", nombre);
    if (res->tiene_datos) {
        fprintf(archivo, "• Cantidad: %d\n• Suma: %d\n• Mínimo: %d\n• Máximo: %d\n• Promedio: %.2f\n• Alertas: %d\n\n", 
                res->cantidad, res->suma, res->minimo, res->maximo, res->promedio, res->alertas);
    } else {
        fprintf(archivo, "• Sin datos\n\n");
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) return 1;
    FILE *entrada = fopen(argv[1], "r");
    if (!entrada) return 1;

    char etiqueta[32]; int total_declarados;
    if (fscanf(entrada, "%31s %d", etiqueta, &total_declarados) != 2) { fclose(entrada); return 1; }
    if (total_declarados < 0 || total_declarados > 200) { fclose(entrada); return 1; }

    Medicion *datos = NULL;
    if (total_declarados > 0) {
        datos = malloc(total_declarados * sizeof(Medicion));
        if (!datos) { fclose(entrada); return 1; }
    }

    ResumenCategoria d = {0,0,0,0,0,0,0}, p = {0,0,0,0,0,0,0}, m = {0,0,0,0,0,0,0};
    int leidos = 0; char cat[15]; int val;

    while (fscanf(entrada, "%14s %d", cat, &val) == 2) {
        if (leidos >= total_declarados || !validar_categoria(cat, val)) { free(datos); fclose(entrada); return 1; }
        
        ResumenCategoria *r = (strcmp(cat, "DISCO") == 0) ? &d : (strcmp(cat, "PROCESOS") == 0) ? &p : &m;
        if (r->tiene_datos == 0) { r->minimo = val; r->maximo = val; r->tiene_datos = 1; }
        r->cantidad++; r->suma += val;
        if (val < r->minimo) r->minimo = val;
        if (val > r->maximo) r->maximo = val;
        if ((r == &d && val >= 80) || (r == &p && val >= 30) || (r == &m && val > 0)) r->alertas++;
        leidos++;
    }
    fclose(entrada);

    if (leidos != total_declarados) { free(datos); return 1; }
    
    if (d.cantidad > 0) d.promedio = (float)d.suma / d.cantidad;
    if (p.cantidad > 0) p.promedio = (float)p.suma / p.cantidad;
    if (m.cantidad > 0) m.promedio = (float)m.suma / m.cantidad;

    FILE *salida = fopen(argv[2], "w");
    if (!salida) { free(datos); return 1; }
    fprintf(salida, "INFORME DE MONITOREO\nEtiqueta: %s\nRegistros: %d\n\n", etiqueta, leidos);
    escribir_categoria(salida, "DISCO", &d);
    escribir_categoria(salida, "PROCESOS", &p);
    escribir_categoria(salida, "PERMISOS", &m);
    fprintf(salida, "Observaciones que cumplen condiciones de alerta: %d.\n", d.alertas + p.alertas + m.alertas);
    fprintf(salida, "Umbrales utilizados con fines didácticos.\n");
    fclose(salida);

    free(datos);
    return 0;
}
EOF

chmod 600 "$CODIGO_C"
echo "-> Compilando sec_engine.c con banderas de rigor -Wall..."
gcc -Wall -Wextra "$CODIGO_C" -o sec_guard/fuentes/sec_engine

echo "-> Ejecutando el analizador en C..."
./sec_guard/fuentes/sec_engine "$INPUT_FILE" "$OUTPUT_FILE"

if [ -f "$OUTPUT_FILE" ]; then
    echo "ETAPA 3 COMPLETADA"
    echo "El informe se ha generado en: $OUTPUT_FILE"
else
    echo "Error: El programa C no genero el archivo de salida."
    exit 1
fi
