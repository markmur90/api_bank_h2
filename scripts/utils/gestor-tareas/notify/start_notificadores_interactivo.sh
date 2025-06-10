#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

mkdir -p ~/api_bank_h2/scripts/.logs

read -p "⏱️ Intervalo (minutos) para notificador de tareas (por defecto 15): " INTERVALO1
INTERVALO1="${INTERVALO1:-15}"

read -p "⏱️ Intervalo (minutos) para notificador VPS (por defecto 30): " INTERVALO2
INTERVALO2="${INTERVALO2:-30}"

nohup bash ~/api_bank_h2/scripts/notificador.sh "" "$INTERVALO1" > ~/api_bank_h2/scripts/.logs/notificador.log 2>&1 &
nohup bash ~/api_bank_h2/scripts/notificador_30.sh "" "$INTERVALO2" > ~/api_bank_h2/scripts/.logs/notificador_30.log 2>&1 &

echo "🔔 Notificadores iniciados con intervalos: $INTERVALO1 min y $INTERVALO2 min"
