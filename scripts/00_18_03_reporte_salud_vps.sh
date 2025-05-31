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

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/00_18_03_reporte_salud_vps/00_18_03_reporte_salud_vps.log"
PROCESS_LOG="$SCRIPT_DIR/logs/00_18_03_reporte_salud_vps/process_00_18_03_reporte_salud_vps.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/00_18_03_reporte_salud_vps_.log"

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
SSH_KEY="${SSH_KEY:-$HOME/.ssh/vps_njalla_nueva}"

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
