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


read -p "✏️ Comentario para el commit: " COMENTARIO_COMMIT
export COMENTARIO_COMMIT

notify_error() {
    notify-send "❌ Error de sincronización" "Revisá logs o conexión SSH"
    command -v canberra-gtk-play &>/dev/null && canberra-gtk-play -i dialog-error
    exit 1
}
trap notify_error ERR

echo "🚀 Subiendo cambios a GitHub..."
bash ~/api_bank_h2/scripts/00_16_01_subir_GitHub.sh

echo "📦 Llamando al VPS para sincronizar..."
ssh -i ~/.ssh/vps_njalla_nueva -p 22 markmur88@80.78.30.242 \
"bash ~/api_bank_h2/scripts/00_24_sync_from_github.sh"

notify-send "✅ Despliegue completo" "Código actualizado en GitHub y sincronizado con el VPS"
command -v canberra-gtk-play &>/dev/null && canberra-gtk-play -i complete



