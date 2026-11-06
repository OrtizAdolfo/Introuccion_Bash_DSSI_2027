#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Error: Debes ingresar exactamente dos numeros enteros."
    echo "Uso: $0 <numero1> <numero2>"
    exit 1
fi

num1=$1
num2=$2

suma=$((num1 + num2))
diferencia=$((num1 - num2))
producto=$((num1 * num2))

echo "Resultados para los numeros $num1 y $num2:"
echo "Suma: $suma"
echo "Diferencia: $diferencia"
echo "Producto: $producto"
