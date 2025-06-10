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

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail


LOG_SISTEMA="$SCRIPTS_DIR/logs/sistema/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_SISTEMA)"

sudo ufw --force reset

# 🚪 Reglas de entrada
sudo ufw allow 22/tcp              # SSH
# sudo ufw limit 22/tcp              # Máx. 6 intentos SSH/minuto/IP
sudo ufw allow 80/tcp              # HTTP (web)
sudo ufw allow 443/tcp             # HTTPS (web segura)
sudo ufw allow 49222/tcp           # Puerto custom para admin/Njalla

# 🔒 Accesos locales (loopback)
sudo ufw allow from 127.0.0.1 to any port 5432
sudo ufw allow from 127.0.0.1 to any port 8000
sudo ufw allow from 127.0.0.1 to any port 8080
sudo ufw allow from 127.0.0.1 to any port 8001
sudo ufw allow from 127.0.0.1 to any port 8011
sudo ufw allow from 127.0.0.1 to any port 9001
sudo ufw allow from 127.0.0.1 to any port 9002
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051
sudo ufw allow from 127.0.0.1 to any port 9052
sudo ufw allow from 127.0.0.1 to any port 9180
sudo ufw allow 9181/tcp comment "Staging - Simulador Gunicorn"
sudo ufw allow from 127.0.0.1 to any port 9053
sudo ufw allow from 127.0.0.1 to any port 9181

# 🧪 Puertos de desarrollo (opcional, descomentar si usás)
# sudo ufw allow 8886/tcp comment "Dev port"
# sudo ufw allow 8887/tcp comment "Dev port"
# sudo ufw allow 8888/tcp comment "Dev port"
# sudo ufw allow 9080/tcp comment "Dev port"

# 📤 Salida necesaria
sudo ufw allow out 53              # DNS
sudo ufw allow out 123/udp         # NTP (hora)
sudo ufw allow out to any port 443 proto tcp

# 🔍 Logging
sudo ufw logging on
sudo ufw logging medium

# 🧱 Reglas de iptables para proteger contra escaneo/ataques comunes
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

# 🔐 Política por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# ✅ Activar UFW
sudo ufw --force enable

echo -e "\033[7;30m🔐 Reglas de UFW aplicadas con éxito.\033[0m" | tee -a $LOG_SISTEMA
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_SISTEMA
echo "" | tee -a $LOG_SISTEMA