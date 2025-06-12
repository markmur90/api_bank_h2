#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Instalación de entorno virtual y PostgreSQL
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


log_info "🐘 Configurando entorno Python y PostgreSQL..."

# Crear entorno virtual si no existe
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
  log_ok "✅ Entorno virtual creado en $VENV_DIR"
fi

# Activar entorno virtual
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

# Instalar dependencias del proyecto
if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
  pip install -r "$PROJECT_ROOT/requirements.txt"
  log_ok "✅ Dependencias instaladas desde requirements.txt"

else
  log_error "❌ No se encontró requirements.txt en $PROJECT_ROOT"
  
  exit 1
fi

# Habilitar e iniciar PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql

log_ok "✅ PostgreSQL habilitado y en ejecución."


