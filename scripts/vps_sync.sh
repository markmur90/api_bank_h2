#!/usr/bin/env bash
set -euo pipefail

# === Variables portables ===

# Rutas en MÁQUINA LOCAL
PROJECT_ROOT="$HOME/api_bank_h2"
NJALLA_ROOT="$HOME/coretransapi"
VENV_PATH="$HOME/Documentos/Entorno/envAPP"

# Rutas en VPS
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
VPS_PROJECT_ROOT="$HOME/api_bank_heroku"
VPS_VENV_PATH="$HOME/envAPP"
VPS_CORETRANS_ROOT="$HOME/coretransapi"

# Exclusiones y logs (en local)
EXCLUDES="$PROJECT_ROOT/scripts/excludes.txt"
LOG_DIR="$PROJECT_ROOT/scripts/logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync.log"

# === Fin de variables ===

echo "📂 Proyecto local: $PROJECT_ROOT" | tee -a "$LOG_FILE"
echo "🧹 Eliminando en VPS archivos excluidos..." | tee -a "$LOG_FILE"

while IFS= read -r pattern; do
  [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
  echo "🗑 Eliminando: $pattern" | tee -a "$LOG_FILE"
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" \
    "rm -rf '$VPS_PROJECT_ROOT/$pattern'" >> "$LOG_FILE" 2>&1
done < "$EXCLUDES"

echo "🔄 Iniciando sincronización local -> VPS..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  --exclude-from="$EXCLUDES" \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$PROJECT_ROOT/" "$VPS_USER@$VPS_IP:$VPS_PROJECT_ROOT" \
  | tee -a "$LOG_FILE"

echo "📡 Ejecutando comandos remotos en el VPS..." | tee -a "$LOG_FILE"
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" << EOF | tee -a "$LOG_FILE"
  set -euo pipefail

  echo "🌐 Entrando en directorio remoto: $VPS_PROJECT_ROOT"
  cd "$VPS_PROJECT_ROOT"

  echo "🔧 Activando entorno virtual en VPS: $VPS_VENV_PATH"
  source "$VPS_VENV_PATH/bin/activate"

  echo "🔁 Ejecutando script 01_full.sh en VPS"
  # bash ./01_full.sh -Q -I -l

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
