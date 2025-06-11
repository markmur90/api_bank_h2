#!/bin/bash

BASE_DIR="$AP_H2_DIR/scripts/gestor-tareas/gestor/.gestor_tareas"

echo "📋 Estado actual de sesiones:"
echo "-----------------------------"

for flag in $AP_H2_DIR/scripts/gestor-tareas/gestor/gestor_activo_*.flag; do
    [ ! -f "$flag" ] && continue
    PROY=$(basename "$flag" | sed 's/gestor_activo_//' | sed 's/.flag//')
    DIR="$BASE_DIR/$PROY"
    LOG="$DIR/tiempos.log"

    if [ -f "$LOG" ]; then
        TOTAL=$(awk '{s+=$1} END {print s}' "$LOG")
    else
        TOTAL=0
    fi

    START=$(stat -c %Y "$flag")
    NOW=$(date +%s)
    SESION=$(( (NOW - START) / 60 ))

    printf "🟢 Proyecto: %-20s | Sesión: %02dm | Total: %dh%02dm\\n" "$PROY" "$SESION" $((TOTAL/60)) $((TOTAL%60))
done
