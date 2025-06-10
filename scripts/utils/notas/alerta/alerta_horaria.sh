#!/bin/bash

LOG_DIR="/home/markmur88/logs"
mkdir -p "$LOG_DIR"

LOG_ALERTAS="$LOG_DIR/alertas_horas.log"
LOG_TOTAL="$LOG_DIR/tiempo_total.log"
LOG_DIA="$LOG_DIR/tiempo_dia.log"
LOG_FECHA="$LOG_DIR/ultima_fecha.log"

HORA_ACTUAL=$(date +"%Y-%m-%d %H:%M:%S")
DIA_HOY=$(date +"%Y-%m-%d")

# Si es un nuevo día, reinicia log diario
if [ ! -f "$LOG_FECHA" ] || [ "$DIA_HOY" != "$(cat $LOG_FECHA)" ]; then
    echo "0" > "$LOG_DIA"
    echo "$DIA_HOY" > "$LOG_FECHA"
fi

# Inicializar si no existen
[ ! -f "$LOG_TOTAL" ] && echo "0" > "$LOG_TOTAL"
[ ! -f "$LOG_DIA" ] && echo "0" > "$LOG_DIA"

# Sumar 60 minutos (1 hora)
TOTAL=$(cat "$LOG_TOTAL")
DIA=$(cat "$LOG_DIA")
TOTAL=$((TOTAL + 60))
DIA=$((DIA + 60))
echo "$TOTAL" > "$LOG_TOTAL"
echo "$DIA" > "$LOG_DIA"

# Formato horas:minutos
function format_time() {
    local MIN=$1
    printf "%02d:%02d" $((MIN / 60)) $((MIN % 60))
}

MENSAJE="⏰ Alerta horaria: $HORA_ACTUAL
📊 Hoy: $(format_time $DIA) hs
📦 Proyecto: $(format_time $TOTAL) hs"

notify-send "⏰ Alerta Horaria" "$MENSAJE"
echo -e "$MENSAJE\n" >> "$LOG_ALERTAS"
