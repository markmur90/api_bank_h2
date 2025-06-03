#!/usr/bin/env bash
set -euo pipefail

# === Configuración básica ===
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
VPS_API_DIR="/home/$VPS_USER/api_bank_heroku"

# === Detectar raíz del proyecto ===
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

echo "📡 Ejecutando comandos en el VPS..."
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" << EOF
  set -euo pipefail
  echo "🌐 Entrando en directorio remoto: $VPS_API_DIR"
  cd "$VPS_API_DIR"
  echo "🔧 Activando entorno virtual en VPS..."
  source "\$HOME/envAPP/bin/activate"

  echo "🔁 Actualizar Django en VPS..."
  python3 manage.py makemigrations
  python3 manage.py migrate
  python3 manage.py collectstatic --noinput

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
