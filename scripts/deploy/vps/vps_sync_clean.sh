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

# Validación de usuario
if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
  echo "⚠️ No ejecutar como root. Cambiando a usuario markmur88..."
  exec sudo -u markmur88 "$0" "$@"
  exit 0
fi

# Detectar raíz del proyecto
BASE_DIR=$(git rev-parse --show-toplevel 2>/dev/null || find "$PWD" -type f -name "manage.py" -exec dirname {} \; | head -n1)
if [[ -z "$BASE_DIR" ]]; then
  echo "❌ No se pudo detectar la raíz del proyecto. Abortando."
  exit 1
fi

# Configuración VPS
EXCLUDES="$DP_VP_DIR/excludes.txt"
LOG_DIR="$BASE_DIR/scripts/logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync_clean.log"

echo "📂 Proyecto: $BASE_DIR" | tee -a "$LOG_FILE"
echo "🧹 Eliminando en VPS archivos excluidos..." | tee -a "$LOG_FILE"

# Eliminar rutas excluidas en el VPS
while IFS= read -r pattern; do
  [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
  echo "🗑 Eliminando: $pattern" | tee -a "$LOG_FILE"
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" \
    "rm -rf /home/markmur88/api_bank_heroku/$pattern" >> "$LOG_FILE" 2>&1
done < "$EXCLUDES"

# Sincronizar contenido del proyecto
echo "🔄 Iniciando sincronización..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  --exclude-from="$EXCLUDES" \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$BASE_DIR/" "markmur88@$VPS_IP:/home/markmur88/api_bank_heroku" \
  | tee -a "$LOG_FILE"

echo "✅ Sincronización completada." | tee -a "$LOG_FILE"
