#!/bin/bash

# === Script: fix_sim_logs.sh ===
# 🔧 Crea directorios y archivos de logs faltantes para los simuladores bancarios

SIM_IDS=("01" "02" "03")
LOGFILES=("simulador_banco.log" "simulador_banco_error.log")

echo "🔍 Corrigiendo estructura de logs para simuladores..."

for id in "${SIM_IDS[@]}"; do
  SIM_DIR="/opt/simulador_banco_${id}/logs"
  echo "📁 Verificando $SIM_DIR"

  sudo mkdir -p "$SIM_DIR"
  for log in "${LOGFILES[@]}"; do
    sudo touch "$SIM_DIR/$log"
  done
  sudo chown -R markmur88:markmur88 "/opt/simulador_banco_${id}"
  echo "✔ Logs corregidos para simulador $id"
done

echo "✅ Todos los logs están creados y listos."
