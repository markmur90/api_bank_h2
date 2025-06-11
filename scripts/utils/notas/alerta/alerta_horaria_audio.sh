#!/bin/bash

LOG_DIR="/home/markmur88/logs"
mkdir -p "$LOG_DIR"

LOG_ALERTAS="$LOG_DIR/alertas_horas.log"
LOG_TOTAL="$LOG_DIR/tiempo_total.log"
LOG_DIA="$LOG_DIR/tiempo_dia.log"
LOG_FECHA="$LOG_DIR/ultima_fecha.log"
LOG_AUDIO="$LOG_DIR/audio_contador.log"

HORA_ACTUAL=$(date +"%Y-%m-%d %H:%M:%S")
DIA_HOY=$(date +"%Y-%m-%d")

# Si es un nuevo día, reinicia log diario
if [ ! -f "$LOG_FECHA" ] || [ "$DIA_HOY" != "$(cat $LOG_FECHA)" ]; then
    echo "0" > "$LOG_DIA"
    echo "$DIA_HOY" > "$LOG_FECHA"
    echo "0" > "$LOG_AUDIO"
fi

# Inicializar si no existen
[ ! -f "$LOG_TOTAL" ] && echo "0" > "$LOG_TOTAL"
[ ! -f "$LOG_DIA" ] && echo "0" > "$LOG_DIA"
[ ! -f "$LOG_AUDIO" ] && echo "0" > "$LOG_AUDIO"

# Sumar 60 minutos (1 hora)
TOTAL=$(cat "$LOG_TOTAL")
DIA=$(cat "$LOG_DIA")
AUDIO_CONT=$(cat "$LOG_AUDIO")

TOTAL=$((TOTAL + 60))
DIA=$((DIA + 60))
AUDIO_CONT=$((AUDIO_CONT + 1))

echo "$TOTAL" > "$LOG_TOTAL"
echo "$DIA" > "$LOG_DIA"
echo "$AUDIO_CONT" > "$LOG_AUDIO"

# Formato horas:minutos
function format_time() {
    local MIN=$1
    printf "%02d horas y %02d minutos" $((MIN / 60)) $((MIN % 60))
}

MENSAJE="⏰ Alerta horaria: $HORA_ACTUAL
📊 Hoy: $(format_time $DIA)
📦 Proyecto: $(format_time $TOTAL)"

notify-send "⏰ Alerta Horaria" "$MENSAJE"
echo -e "$MENSAJE\n" >> "$LOG_ALERTAS"

# 🎤 Cada 4 horas, anunciar por audio
if [ $((AUDIO_CONT % 4)) -eq 0 ]; then
    TEXTO="Alerta horaria. Tiempo trabajado hoy: $(format_time $DIA). Tiempo acumulado del proyecto: $(format_time $TOTAL)."
    espeak "$TEXTO" --stdout | aplay
fi
