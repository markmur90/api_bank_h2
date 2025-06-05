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

# === Variables portables ===

# Rutas en MÁQUINA LOCAL
BASE_DIR="$AP_H2_DIR"
NJALLA_ROOT="/home/markmur88/coretransapi"
VENV_PATH="/home/markmur88/Documentos/Entorno/envAPP"

# Rutas en VPS
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
VPS_BASE_DIR="/home/markmur88/api_bank_heroku"
VPS_VENV_PATH="/home/markmur88/envAPP"
VPS_CORETRANS_ROOT="/home/markmur88/coretransapi"

# Exclusiones y logs (en local)
EXCLUDES="$DP_VP_DIR/excludes.txt"
LOG_DIR="$BASE_DIR/scripts/logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync.log"

# === Fin de variables ===

echo "📂 Proyecto local: $BASE_DIR" | tee -a "$LOG_FILE"
echo "🧹 Eliminando en VPS archivos excluidos..." | tee -a "$LOG_FILE"

while IFS= read -r pattern; do
  [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
  echo "🗑 Eliminando: $pattern" | tee -a "$LOG_FILE"
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" \
    "rm -rf '$VPS_BASE_DIR/$pattern'" >> "$LOG_FILE" 2>&1
done < "$EXCLUDES"

echo "🔄 Iniciando sincronización local -> VPS..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  --exclude-from="$EXCLUDES" \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$BASE_DIR/" "$VPS_USER@$VPS_IP:$VPS_BASE_DIR" \
  | tee -a "$LOG_FILE"

echo "📡 Ejecutando comandos remotos en el VPS..." | tee -a "$LOG_FILE"
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" << EOF | tee -a "$LOG_FILE"
  set -euo pipefail

  echo "🌐 Entrando en directorio remoto: $VPS_BASE_DIR"
  cd "$VPS_BASE_DIR"

  echo "🔧 Activando entorno virtual en VPS: $VPS_VENV_PATH"
  source "$VPS_VENV_PATH/bin/activate"

  echo "🔁 Ejecutando script 01_full.sh en VPS"
  bash /home/markmur88/api_bank_heroku/scripts/menu/01_full.sh -Q -I -l

  echo "🔁 Reiniciando servicios en VPS..."
  sudo supervisorctl restart coretransapi
  sudo systemctl reload nginx

  echo "📋 Estado del servicio coretransapi en VPS:"
  sudo supervisorctl status coretransapi

  echo "📄 Últimos logs de error en VPS:"
  tail -n 10 /var/log/supervisor/coretransapi.err.log

  echo "✅ Comandos remotos completados."
EOF

echo "✅ Sincronización completada." | tee -a "$LOG_FILE"
