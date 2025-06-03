#!/usr/bin/env bash
set -euo pipefail

# === Configuración básica ===
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
VPS_API_DIR="/home/$VPS_USER/api_bank_heroku"

# === Detectar raíz del proyecto ===
# PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || find "$PWD" -type f -name "manage.py" -exec dirname {} \; | head -n1)
# if [[ -z "$PROJECT_ROOT" ]]; then
#   echo "❌ No se pudo detectar la raíz del proyecto. Abortando."
#   exit 1
# fi

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"


EXCLUDES="$PROJECT_ROOT/scripts/excludes.txt"
LOG_DIR="$PROJECT_ROOT/scripts/logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync.log"

echo "📂 Proyecto: $PROJECT_ROOT" | tee -a "$LOG_FILE"
echo "🧹 Eliminando en VPS archivos excluidos..." | tee -a "$LOG_FILE"

while IFS= read -r pattern; do
  [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
  echo "🗑 Eliminando: $pattern" | tee -a "$LOG_FILE"
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" \
    "rm -rf '$VPS_API_DIR/$pattern'" >> "$LOG_FILE" 2>&1
done < "$EXCLUDES"

echo "🔄 Iniciando sincronización..." | tee -a "$LOG_FILE"
rsync -avz --delete \
  --exclude-from="$EXCLUDES" \
  -e "ssh -i $SSH_KEY -p $VPS_PORT" \
  "$PROJECT_ROOT/" "$VPS_USER@$VPS_IP:$VPS_API_DIR" \
  | tee -a "$LOG_FILE"

echo "✅ Sincronización completada." | tee -a "$LOG_FILE"
