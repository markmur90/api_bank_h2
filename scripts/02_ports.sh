#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Verificación y liberación de puertos
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

log_info "🔍 Verificando puertos permitidos por UFW y liberando procesos activos..."

# Puertos gestionados por el sistema (según UFW)
PUERTOS=(
    22     # SSH
    80     # Nginx HTTP
    443    # Nginx HTTPS
    8000   # Gunicorn
    5432   # PostgreSQL
    2222   # Honeypot SSH
    9001   # Supervisor
    9050   # Tor SOCKS5
    9051   # Tor Control
    18080  # Monero P2P
    18082  # Wallet RPC
    18089  # Wallet RPC múltiple
    18090
    18091
    18092
    18093
    18094
    18095
    18096
    18097
    18098
    18099
    18100
    35729  # Livereload
    5000   # Ghost API
)

PUERTOS_OCUPADOS=0

for PUERTO in "${PUERTOS[@]}"; do
    if lsof -i tcp:"$PUERTO" &>/dev/null; then
        PUERTOS_OCUPADOS=$((PUERTOS_OCUPADOS + 1))
        sudo fuser -k "${PUERTO}"/tcp || true
        echo -e "\033[7;30m✅ Puerto $PUERTO liberado.\033[0m" | tee -a "$LOG_FILE"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    fi
done

if [[ "$PUERTOS_OCUPADOS" -eq 0 ]]; then
    echo -e "\033[7;31m🚫 No se encontraron procesos en los puertos definidos.\033[0m" | tee -a "$LOG_FILE"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
fi

log_ok "✅ Verificación y limpieza de puertos completada."

echo ""

