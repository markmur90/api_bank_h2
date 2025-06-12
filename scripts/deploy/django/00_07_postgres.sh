#!/usr/bin/env bash
# Configura PostgreSQL, usuario y base de datos

set -euo pipefail

# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BASE_DIR="$AP_H2_DIR"
LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname "$LOG_DEPLOY")"

# Logging inicial
{
echo ""
echo "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $(basename "$0")"
echo "═══════════════════════════════════════════"
} | tee -a "$LOG_DEPLOY"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando." | tee -a "$LOG_DEPLOY"; exit 1' ERR

# 🔍 Verificar e instalar PostgreSQL si falta
echo "🔍 Verificando PostgreSQL..." | tee -a "$LOG_DEPLOY"

if ! command -v psql &>/dev/null; then
    echo "⚠️ PostgreSQL no encontrado. Instalando..." | tee -a "$LOG_DEPLOY"
    OS="$(uname -s)"
    if [[ "$OS" == "Linux" ]]; then
        sudo apt update && sudo apt install -y postgresql postgresql-contrib
    elif [[ "$OS" == "Darwin" ]]; then
        brew update && brew install postgresql
    else
        echo "❌ OS no compatible"
        exit 1
    fi
    echo "♻️ PostgreSQL instalado. Reiniciando script..." | tee -a "$LOG_DEPLOY"
    exec "$0" "$@"
fi

# 🧠 Identificar servicio PostgreSQL y asegurarse que esté activo
OS="$(uname -s)"
if [[ "$OS" == "Linux" ]]; then
    PG_SERVICE=$(systemctl list-unit-files --type=service | grep -E '^postgresql.*\.service' | awk '{print $1}' | head -n1)
    if [[ -z "$PG_SERVICE" ]]; then
        echo "❌ No se detectó un servicio PostgreSQL válido" | tee -a "$LOG_DEPLOY"
        exit 1
    fi
    if ! systemctl is-active --quiet "$PG_SERVICE"; then
        echo "🔌 Iniciando PostgreSQL..." | tee -a "$LOG_DEPLOY"
        sudo systemctl enable "$PG_SERVICE"
        sudo systemctl start "$PG_SERVICE"
    fi
elif [[ "$OS" == "Darwin" ]]; then
    brew services start postgresql
fi

# 🐍 Crear entorno virtual y dependencias
python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"
pip install --upgrade pip
echo "📦 Instalando dependencias..." | tee -a "$LOG_DEPLOY"
pip install -r "$BASE_DIR/requirements.txt"

# === CREDENCIALES ===
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"

export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"

# 🗝️ Crear ~/.pgpass para no pedir contraseña
echo "${DB_HOST}:5432:*:${DB_USER}:${DB_PASS}" > "/home/${DB_USER}/.pgpass"
chmod 600 "/home/${DB_USER}/.pgpass"
chown ${DB_USER}:${DB_USER} "/home/${DB_USER}/.pgpass"

# 🧑‍🔧 Crear usuario si no existe
sudo -u postgres psql <<-EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;
ALTER USER ${DB_USER} WITH SUPERUSER;
GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
EOF

# 💣 Si existe, eliminar BDD
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
    echo "⚠️ Borrando base de datos existente: ${DB_NAME}" | tee -a $LOG_DEPLOY
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';"
    sudo -u postgres psql -c "DROP DATABASE ${DB_NAME};"
fi

# 🆕 Crear nueva BDD
sudo -u postgres psql <<-EOF
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

echo -e "\033[7;30m✅ Base de datos y usuario listos.\033[0m" | tee -a $LOG_DEPLOY

# chmodtree
cd $AP_HK_DIR
bash restore_and_upload_force.sh