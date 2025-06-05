#!/usr/bin/env bash

# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
BACKUPDIR="/home/markmur88/backup"
BANK_GHOST="/home/markmur88/bank_ghost"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
BASE_DIR="$AP_H2_DIR"
VPS_BASE_DIR="/home/markmur88/api_bank_heroku"
VPS_VENV_PATH="/home/markmur88/envAPP"
VPS_CORETRANS_ROOT="/home/markmur88/coretransapi"

EXCLUDES="/home/markmur88/api_bank_h2/scripts/deploy/vps/excludes.txt"
LOG_DIR="$SCRIPTS_DIR/logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync_clean.log"

set -euo pipefail

# Validación de usuario
if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
  echo "⚠️ No ejecutar como root. Cambiando a usuario markmur88..."
  exec sudo -u markmur88 "$0" "$@"
  exit 0
fi

# Crear carpetas remotas si no existen
for DIR in "$AP_H2_DIR" "$AP_HK_DIR" "$BACKUPDIR" "$BANK_GHOST"; do
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" "mkdir -p $DIR"
done

# # Detectar raíz del proyecto
# BASE_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
# if [[ -z "$BASE_DIR" ]]; then
#   manage_path=$(find "$PWD" -type f -name "manage.py" -print -quit)
#   BASE_DIR=$(dirname "$manage_path")
# fi

# echo "📂 Proyecto: $BASE_DIR" | tee -a "$LOG_FILE"

# === FUNCION PARA LIMPIEZA DE EXCLUSIONES ===
limpiar_patrones() {
  REMOTE_DIR=$1
  echo "🧹 Limpiando en VPS ($REMOTE_DIR) archivos excluidos..." | tee -a "$LOG_FILE"
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    echo "🗑 Eliminando: $pattern" | tee -a "$LOG_FILE"

    if [[ "$pattern" == */ ]]; then
      ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" \
        "find $REMOTE_DIR -type d -name '${pattern%/}' -exec rm -rf {} +" >> "$LOG_FILE" 2>&1
    elif [[ "$pattern" == *\** ]]; then
      ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" \
        "find $REMOTE_DIR -type f -name '$pattern' -exec rm -f {} +" >> "$LOG_FILE" 2>&1
    else
      ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" \
        "find $REMOTE_DIR -name '$pattern' -exec rm -f {} +" >> "$LOG_FILE" 2>&1
    fi
  done < "$EXCLUDES"
}


echo "🔥 Eliminando contenido de carpetas remotas..." | tee -a "$LOG_FILE"
for dir in "$AP_HK_DIR" "$AP_H2_DIR" "$BANK_GHOST"; do
  echo "🧨 Borrando contenido de $dir en VPS" | tee -a "$LOG_FILE"
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" "rm -rf $dir/* $dir/.* 2>/dev/null || true"
done

# === LIMPIEZA Y SYNC ===
limpiar_patrones "$AP_HK_DIR"
limpiar_patrones "$BANK_GHOST"


echo "🔄 Sincronizando proyecto hacia api_bank_heroku (con exclusiones)..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  --exclude-from="$EXCLUDES" \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$BASE_DIR/" "markmur88@$VPS_IP:$AP_HK_DIR/" \
  | tee -a "$LOG_FILE"

echo "🔄 Sincronizando proyecto hacia api_bank_h2 (sin exclusiones)..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$BASE_DIR/" "markmur88@$VPS_IP:$AP_H2_DIR/" \
  | tee -a "$LOG_FILE"

echo "🔄 Sincronizando carpeta de backup..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$BACKUPDIR/" "markmur88@$VPS_IP:$BACKUPDIR/" \
  | tee -a "$LOG_FILE"

echo "🔄 Sincronizando carpeta de bank_ghost..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  --exclude-from="$EXCLUDES" \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$BANK_GHOST/" "markmur88@$VPS_IP:$BANK_GHOST/" \
  | tee -a "$LOG_FILE"


echo "📡 Ejecutando comandos remotos en el VPS..." | tee -a "$LOG_FILE"
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" << EOF | tee -a "$LOG_FILE"
  set -euo pipefail

  echo "🌐 Entrando en directorio remoto: $VPS_BASE_DIR"
  cd "$VPS_BASE_DIR"

  echo "🔧 Activando entorno virtual en VPS: $VPS_VENV_PATH"
  source "$VPS_VENV_PATH/bin/activate"

  # echo "🔁 Ejecutando script 01_full.sh en VPS"
  # bash /home/markmur88/api_bank_heroku/scripts/menu/01_full.sh -Q -I -l

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
