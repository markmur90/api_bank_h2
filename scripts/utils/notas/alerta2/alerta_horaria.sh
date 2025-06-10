#!/bin/bash

# Ruta donde se guardan los tiempos
LOG_DIR="$HOME/.tiempos"
mkdir -p "$LOG_DIR"

# Archivos
DIA=$(date +"%Y-%m-%d")
PROYECTO_FILE="$LOG_DIR/proyecto_total.log"
DIA_FILE="$LOG_DIR/$DIA.log"

# Sumar un minuto al día
echo 1 >> "$DIA_FILE"
MINUTOS_HOY=$(awk '{s+=$1} END {print s}' "$DIA_FILE")
HORAS_HOY=$((MINUTOS_HOY / 60))

# Sumar al total del proyecto
echo 1 >> "$PROYECTO_FILE"
MINUTOS_TOTAL=$(awk '{s+=$1} END {print s}' "$PROYECTO_FILE")
HORAS_TOTAL=$((MINUTOS_TOTAL / 60))

# Mensaje
MSG="⏰ Alerta horaria\n📅 Hoy: $MINUTOS_HOY min ($HORAS_HOY hs)\n🧱 Proyecto: $MINUTOS_TOTAL min ($HORAS_TOTAL hs)"

# Enviar por Telegram
"$HOME/api_bank_h2/scripts/utils/token/enviar_telegram.sh" "$MSG"
