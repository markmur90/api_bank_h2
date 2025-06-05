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


SCRIPT_NAME="$(basename "$0")"

LOG_FILE="$SCRIPTS_DIR/logs/00_18_03_reporte_salud_vps/00_18_03_reporte_salud_vps.log"
PROCESS_LOG="$SCRIPTS_DIR/logs/00_18_03_reporte_salud_vps/process_00_18_03_reporte_salud_vps.log"
LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/00_18_03_reporte_salud_vps_.log"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PROCESS_LOG")" "$(dirname "$LOG_DEPLOY")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

# Parámetros
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-80.78.30.242}"
SSH_KEY="${SSH_KEY:-/home/markmur88/.ssh/vps_njalla_nueva}"

echo "📡 Conectando a VPS $VPS_USER@$VPS_IP..."
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" bash << 'EOF'
echo "🩺 Uptime:"
uptime
echo ""

echo "🧠 Memoria:"
free -h
echo ""

echo "🗂 Espacio en disco:"
df -h /
echo ""

echo "🔥 Procesos Gunicorn:"
ps aux | grep gunicorn | grep -v grep
echo ""

echo "🌐 Estado Nginx y Supervisor:"
sudo systemctl status nginx | grep Active
sudo systemctl status supervisor | grep Active
EOF
