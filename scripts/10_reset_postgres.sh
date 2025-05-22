#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Reseteo de base de datos PostgreSQL
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

# Validaciones mínimas
DB_NAME="${DB_NAME:-mydatabase}"
DB_USER="${DB_USER:-markmur88}"
DB_PASS="${DB_PASS:-Ptf8454Jd55}"
DB_HOST="${DB_HOST:-localhost}"

# Preparar log
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

crear_usuario_y_privilegios() {
  log_info "🔐 Verificando o creando usuario '$DB_USER'..."

  sudo -u postgres psql <<-EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;

ALTER USER ${DB_USER} WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
EOF
}

recrear_base_datos() {
  log_info "🧨 Verificando si existe la base '$DB_NAME'..."

  if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
    log_info "💣 Terminando conexiones activas..."
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';"
    log_info "🗑️ Eliminando base de datos '$DB_NAME'"
    sudo -u postgres psql -c "DROP DATABASE ${DB_NAME};"
  fi

  log_info "📦 Creando nueva base de datos '$DB_NAME'"
  sudo -u postgres psql <<-EOF
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CREATE ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF
}

log_info "🔄 Iniciando reseteo completo de PostgreSQL..."
crear_usuario_y_privilegios
recrear_base_datos
log_ok "✅ Base de datos y usuario PostgreSQL recreados correctamente."

