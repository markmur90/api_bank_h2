#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || { echo "❌ No se pudo acceder a $BASE_DIR"; exit 1; }

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo -e "\033[1;31m❌ No se encontró el archivo .env en $BASE_DIR\033[0m"
  exit 1
fi

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "🛡️  Iniciando configuración avanzada de Tor..."

if ! command -v tor >/dev/null 2>&1; then
  log_info "Tor no está instalado. Instalando..."
  sudo apt-get update && sudo apt-get install -y tor || {
    log_error "Falló la instalación de Tor"
    exit 1
  }
fi

# Detectar archivo torrc usado por Tor
TORRC_PATH=""
# Buscamos el comando de Tor y extraemos el parámetro -f si existe
TOR_PROC=$(pgrep -af tor | grep -v grep || true)

if [[ -z "$TOR_PROC" ]]; then
  log_error "No se encontró proceso Tor activo. Abortando."
  exit 1
fi

# Extraemos el path de torrc si existe -f, si no, ponemos el default
if echo "$TOR_PROC" | grep -q -- "-f"; then
  TORRC_PATH=$(echo "$TOR_PROC" | grep -oP '(?<=-f )\S+')
  log_info "Tor usa archivo de configuración personalizado: $TORRC_PATH"
else
  TORRC_PATH="/etc/tor/torrc"
  log_info "Tor usa archivo de configuración por defecto: $TORRC_PATH"
fi

# Backup del archivo torrc
sudo cp "$TORRC_PATH" "${TORRC_PATH}.bak_$(date +%Y%m%d_%H%M%S)"
log_info "Backup de torrc creado."

# Preparar variables para actualización
TOR_PASS="${TOR_PASS:-Ptf8454Jd55}"
log_info "Contraseña ControlPort tomada de TOR_PASS: $TOR_PASS"

log_info "Generando hash de la contraseña para ControlPort..."
HASHED_PASS=$(tor --hash-password "$TOR_PASS" | tail -n 1)

# Función para agregar o reemplazar una directiva en torrc
replace_or_add_line() {
  local file="$1"
  local directive="$2"
  local value="$3"
  if sudo grep -q "^$directive" "$file"; then
    sudo sed -i "s|^$directive.*|$directive $value|" "$file"
    log_info "Actualizada directiva $directive"
  else
    echo "$directive $value" | sudo tee -a "$file" > /dev/null
    log_info "Añadida directiva $directive"
  fi
}

replace_or_add_line "$TORRC_PATH" "ControlPort" "9051"
replace_or_add_line "$TORRC_PATH" "CookieAuthentication" "0"
replace_or_add_line "$TORRC_PATH" "HashedControlPassword" "$HASHED_PASS"

log_info "Reiniciando servicio Tor..."
sudo systemctl enable tor
sudo systemctl restart tor || {
  log_error "No se pudo reiniciar el servicio Tor"
  exit 1
}

sleep 3  # esperar que Tor arranque bien

log_info "Comprobando autenticación ControlPort..."

AUTH_CMD=$(printf 'AUTHENTICATE "%s"\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$TOR_PASS")
CHECK=$(echo -e "$AUTH_CMD" | nc 127.0.0.1 9051 || true)

if echo "$CHECK" | grep -q "250 OK"; then
  log_ok "✅ Tor autenticado correctamente con ControlPort."
else
  log_error "❌ Error autenticando con Tor ControlPort:"
  echo "$CHECK" | tee -a "$LOG_FILE"
  exit 1
fi

log_ok "✅ Configuración avanzada de Tor completada correctamente."

