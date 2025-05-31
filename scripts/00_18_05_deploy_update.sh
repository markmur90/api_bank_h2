#!/usr/bin/env bash
set -euo pipefail

# === Parámetros ===
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-80.78.30.242}"
SSH_KEY="${3:-$HOME/.ssh/vps_njalla_nueva}"
PROYECTO_DIR="/home/$VPS_USER/coretransapi"
VENV_DIR="/home/$VPS_USER/envAPP"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/00_18_05_deploy_update/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "🔁 Ejecutando actualización remota en $VPS_USER@$VPS_IP"

ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" bash <<EOF
set -e

echo "📥 Actualizando repositorio Django..."
cd "$PROYECTO_DIR"
git pull

echo "🐍 Activando entorno virtual..."
source "$VENV_DIR/bin/activate"

echo "📦 Instalando nuevas dependencias (si hay)..."
pip install --upgrade pip
pip install -r "$PROYECTO_DIR/requirements.txt"

echo "⚙️ Ejecutando migraciones..."
python manage.py migrate

echo "🎨 Recolectando archivos estáticos..."
python manage.py collectstatic --noinput

echo "🧠 Reiniciando coretransapi via Supervisor..."
sudo supervisorctl restart coretransapi

echo "🌐 Verificando y recargando Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Actualización completa en $HOSTNAME"
EOF
