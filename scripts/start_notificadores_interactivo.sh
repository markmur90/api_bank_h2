#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/Documentos/GitHub/api_bank_h2/scripts/.logs

read -p "⏱️ Intervalo (minutos) para notificador de tareas (por defecto 15): " INTERVALO1
INTERVALO1="${INTERVALO1:-15}"

read -p "⏱️ Intervalo (minutos) para notificador VPS (por defecto 30): " INTERVALO2
INTERVALO2="${INTERVALO2:-30}"

nohup bash ~/Documentos/GitHub/api_bank_h2/scripts/notificador.sh "" "$INTERVALO1" > ~/Documentos/GitHub/api_bank_h2/scripts/.logs/notificador.log 2>&1 &
nohup bash ~/Documentos/GitHub/api_bank_h2/scripts/notificador_30.sh "" "$INTERVALO2" > ~/Documentos/GitHub/api_bank_h2/scripts/.logs/notificador_30.log 2>&1 &

echo "🔔 Notificadores iniciados con intervalos: $INTERVALO1 min y $INTERVALO2 min"
