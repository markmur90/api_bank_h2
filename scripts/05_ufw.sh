#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Configuración de UFW (Firewall)
# ===========================

# Cargar entorno desde .env
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

# Preparar log
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "🔐 Aplicando reglas de firewall UFW para entorno Ghost + Bank + XMR..."

# Política por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Reglas básicas
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 8000/tcp    # HTTPS
sudo ufw allow 49222/tcp   # HTTPS NJALLA

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

log_ok "✅ Reglas de UFW aplicadas correctamente."
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

