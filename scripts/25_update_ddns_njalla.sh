#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Actualización de DDNS (Njalla)
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

# Configuración Njalla (ajustables o movibles a .env si se desea)
SUBDOMINIO="api"
DOMINIO="coretransapi.com"
DDNS_KEY="REEMPLAZAR_CON_TU_CLAVE_DDNS"  # << Asegúrate de configurarla

USE_IPV6=false
USE_BOTH=false
QUIET=false

# Preparar log
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "🌐 Actualizando DDNS en Njalla para $SUBDOMINIO.$DOMINIO..."

# Construir URL de actualización
BASE_URL="https://njal.la/update/?h=$SUBDOMINIO.$DOMINIO&k=$DDNS_KEY"

if [ "$USE_BOTH" = true ]; then
    URL="$BASE_URL&auto&aaaa=$(curl -s https://api64.ipify.org)"
elif [ "$USE_IPV6" = true ]; then
    URL="$BASE_URL&aaaa=$(curl -s https://api64.ipify.org)"
else
    URL="$BASE_URL&auto"
fi

[ "$QUIET" = true ] && URL="${URL}&quiet"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$URL")
BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$STATUS" = "200" ]; then
  log_ok "✅ DDNS actualizado correctamente en Njalla"
  echo "📦 Respuesta:" | tee -a "$LOG_FILE"
  echo "$BODY" | tee -a "$LOG_FILE"
else
  log_error "❌ Error al actualizar ($STATUS)"
  echo "$BODY" | tee -a "$LOG_FILE"
  exit 1
fi

