#!/usr/bin/env bash
set -euo pipefail

# Validación de usuario
if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
  echo "⚠️ No ejecutar como root. Cambiando a usuario markmur88..."
  exec sudo -u markmur88 "$0" "$@"
  exit 0
fi

# Detectar raíz del proyecto
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || find "$PWD" -type f -name "manage.py" -exec dirname {} \; | head -n1)
if [[ -z "$PROJECT_ROOT" ]]; then
  echo "❌ No se pudo detectar la raíz del proyecto. Abortando."
  exit 1
fi

# Configuración VPS
EXCLUDES="$PROJECT_ROOT/scripts/excludes.txt"
LOG_DIR="$PROJECT_ROOT/scripts/logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync_clean.log"

echo "📂 Proyecto: $PROJECT_ROOT" | tee -a "$LOG_FILE"
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
  "$PROJECT_ROOT/" "markmur88@$VPS_IP:/home/markmur88/api_bank_heroku" \
  | tee -a "$LOG_FILE"

echo "✅ Sincronización completada." | tee -a "$LOG_FILE"
