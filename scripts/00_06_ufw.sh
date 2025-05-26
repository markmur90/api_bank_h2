#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SISTEMA="$SCRIPT_DIR/logs/sistema/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_SISTEMA)"


sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Reglas básicas
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 8000/tcp    # HTTPS
sudo ufw allow 18080/tcp    # HTTPS
sudo ufw allow 18081/tcp    # HTTPS
sudo ufw allow 28080/tcp    # HTTPS
sudo ufw allow 28081/tcp    # HTTPS
sudo ufw allow 49222/tcp   # HTTPS NJALLA
sudo ufw allow out to any port 443 #PUSH
# Gunicorn y PostgreSQL solo local
sudo ufw allow from 127.0.0.1 to any port 8000
sudo ufw allow from 127.0.0.1 to any port 8011
sudo ufw allow from 127.0.0.1 to any port 8001
sudo ufw allow from 127.0.0.1 to any port 5432
# Honeypot SSH
sudo ufw allow 2222/tcp
# Supervisor local
sudo ufw allow from 127.0.0.1 to any port 9001
# Tor
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051
# DNS y NTP salientes
sudo ufw allow out 53
sudo ufw allow out 123/udp
# Heroku CLI saliente
sudo ufw allow out to any port 443
# Monero (XMR)
sudo ufw allow 18080/tcp                                     # Nodo P2P abierto
sudo ufw allow proto tcp from 127.0.0.1 to any port 18082    # Wallet RPC local
sudo ufw allow proto tcp from 127.0.0.1 to any port 18089:18100  # Rango wallets
# Livereload (local)
sudo ufw allow from 127.0.0.1 to any port 35729
# Ghost API (local)
sudo ufw allow from 127.0.0.1 to any port 5000
# Activar UFW
sudo ufw --force enable
echo -e "\033[7;30m🔐 Reglas de UFW aplicadas con éxito.\033[0m" | tee -a $LOG_SISTEMA
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_SISTEMA
echo "" | tee -a $LOG_SISTEMA
