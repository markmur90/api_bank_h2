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
set -e

# === Variables (ajustables) ===
IP_VPS="80.78.30.242"
verificar_huella_ssh "$IP_VPS"


# === Parámetros ===
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-80.78.30.242}"
SSH_KEY="${3:-/home/markmur88/.ssh/vps_njalla_nueva}"
SSH_PORT="${4:-49222}"
DOMAIN="${5:-api.coretransapi.com}"
PUERTOS="${6:-80 443 49222}"

SCRIPT_NAME="$(basename "$0")"

LOG_FILE="$SCRIPTS_DIR/logs/check_ssl_ports/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "🔍 Verificando SSL y puertos abiertos en $VPS_USER@$VPS_IP..."

ssh -i "$SSH_KEY" -p "$SSH_PORT" "$VPS_USER@$VPS_IP" bash <<EOF
set -e

echo "🔐 Certificados SSL para $DOMAIN:"
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    ls -l "/etc/letsencrypt/live/$DOMAIN"
else
    echo "❌ Directorio SSL no encontrado: /etc/letsencrypt/live/$DOMAIN"
fi

echo -e "\n🌐 Verificación de puertos:"
for PORT in $PUERTOS; do
    echo -n "Puerto $PORT: "
    ss -tuln | grep ":$PORT" &>/dev/null && echo "🟢 Abierto" || echo "🔴 Cerrado"
done
EOF

echo "✅ Revisión completada."
