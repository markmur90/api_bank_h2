#!/usr/bin/env bash

# Auto-reinvoca con bash si no está corriendo con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Función para autolimpieza de huella SSH
verificar_huella_ssh() {
    local host="$1"
    echo "🔍 Verificando huella SSH para $host..."
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$host" "exit" >/dev/null 2>&1 || {
        echo "⚠️  Posible conflicto de huella, limpiando..."
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e

# === Variables (ajustables) ===
IP_VPS="80.78.30.242"
verificar_huella_ssh "$IP_VPS"


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
