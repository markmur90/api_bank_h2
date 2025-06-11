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
# ⚠️ Detectar y cambiar a usuario no-root si es necesario


if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
    echo "🧍 Ejecutando como root. Cambiando a usuario 'markmur88'..."
    exec sudo -i -u markmur88 "$0" "$@"
    exit 0
fi

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
        ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e -x

# === Variables (ajustables) ===
IP_VPS="80.78.30.242"
# verificar_huella_ssh "$IP_VPS"


# === Parámetros ===
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-80.78.30.242}"
SSH_KEY="${3:-/home/markmur88/.ssh/vps_njalla_nueva}"
PROYECTO_DIR="/home/$VPS_USER/api_bank_h2"
VENV_DIR="/home/$VPS_USER/envAPP"

SCRIPT_NAME="$(basename "$0")"

LOG_FILE="$SCRIPTS_DIR/logs/00_18_05_deploy_update/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"



echo ""


echo "🔁 Ejecutando actualización remota en $VPS_USER@$VPS_IP"

ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" bash <<EOF
set -e
echo ""

echo "📥 Actualizando repositorio Django..."
cd "$PROYECTO_DIR"

echo ""
echo "🐍 Activando entorno virtual..."
source "$VENV_DIR/bin/activate"

echo ""
echo "📦 Instalando nuevas dependencias (si hay)..."
pip install --upgrade pip
pip install -r "$PROYECTO_DIR/requirements.txt"

echo ""
cd /home/markmur88/api_bank_h2
bash restore_and_upload_force.sh


# cd "$PROYECTO_DIR"

# git fetch origin
# git reset --hard origin/api-bank
# git add .gitignore
# git commit -m "Actualizar .gitignore para ignorar caches, entornos y media"

# git rm -r --cached .
# git add .
# git commit -m "Eliminar del índice los archivos ignorados"


# git config --global user.email "markmur90@proton.me"
# git config --global user.name  "markmur90"

# git pull origin api-bank



echo "⚙️ Ejecutando migraciones..."
python manage.py migrate
echo ""

echo "🎨 Recolectando archivos estáticos..."
python manage.py collectstatic --noinput
echo ""

sleep 3
echo ""

echo ""

sleep 3
echo ""

echo "🧠 Reiniciando coretransapi via Supervisor..."
sudo supervisorctl restart coretransapi
echo ""
sleep 3

echo "🌐 Verificando y recargando Nginx..."
sudo nginx -t && sudo systemctl reload nginx
echo ""

sleep 3

echo "✅ Actualización completa en $HOSTNAME"
EOF
