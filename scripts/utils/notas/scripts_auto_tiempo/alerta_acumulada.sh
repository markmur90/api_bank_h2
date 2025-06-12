#!/bin/bash

# === CONFIGURACIÓN ===
DIR_LOG="/home/markmur88/logs_tiempo"
mkdir -p "$DIR_LOG"
ARCHIVO_LOG="$DIR_LOG/tiempo_acumulado.log"
ARCHIVO_RESUMEN_DIARIO="$DIR_LOG/resumen_diario.log"
ARCHIVO_RESUMEN_PROYECTO="$DIR_LOG/resumen_proyecto.log"

# === CALCULAR TIEMPO ===
echo "$(date +%Y-%m-%d_%H:%M:%S) - Se ha acumulado 60 minutos (1 hora)" >> "$ARCHIVO_LOG"

# === ACTUALIZAR RESÚMENES ===
# Resumen diario
FECHA_HOY=$(date +%Y-%m-%d)
MINUTOS_HOY=$(grep "$FECHA_HOY" "$ARCHIVO_LOG" | wc -l)
echo "$FECHA_HOY: $((MINUTOS_HOY * 60)) minutos, $MINUTOS_HOY horas" > "$ARCHIVO_RESUMEN_DIARIO"

# Resumen del proyecto
TOTAL_MINUTOS=$(wc -l < "$ARCHIVO_LOG")
echo "Total acumulado del proyecto: $((TOTAL_MINUTOS * 60)) minutos, $TOTAL_MINUTOS horas" > "$ARCHIVO_RESUMEN_PROYECTO"

# === MOSTRAR EN PANTALLA ===
echo "⏱️ Tiempo acumulado hoy: $((MINUTOS_HOY * 60)) minutos, $MINUTOS_HOY horas"
echo "📊 Tiempo total del proyecto: $((TOTAL_MINUTOS * 60)) minutos, $TOTAL_MINUTOS horas"
