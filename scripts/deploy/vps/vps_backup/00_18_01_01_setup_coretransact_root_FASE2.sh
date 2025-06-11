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
# ⚠️ Detectar y cambiar a usuario no-root si es necesario


if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
    echo "🧍 Ejecutando como root. Cambiando a usuario 'markmur88'..."
    
    # # Solicita la contraseña de sudo
    # read -s -p "🔐 Ingresá la contraseña de 'markmur88': " SUDO_PASS
    # echo
    SUDO_PASS="Ptf8454Jd55"
    # Ejecuta el script como markmur88 usando sudo con contraseña
    echo "$SUDO_PASS" | sudo -S -u markmur88 "$0" "$@"
    exit 0
fi

# Auto-reinvoca con bash si no está corriendo con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Función para autolimpieza de huella SSH
verificar_huella_ssh() {
    local host="$1"
    echo "🔍 Verificando huella SSH para $host..."
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$host" "exit" >/dev/null 2>&1 || {
        echo "⚠️  Posible conflicto de huella, limpiando..."
        ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$host" >/dev/null
    }

}
#!/usr/bin/env bash
set -e -x

SCRIPT_NAME="$(basename "$0")"

PROJECT_DIR="$BASE_DIR"


# === Variables (ajustables) ===
IP_VPS="80.78.30.242"
# verificar_huella_ssh "$IP_VPS"

# ==============================================================
# Auto-reinvoca con bash si no está corriendo con bash
# ============================================================== 
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# ==============================================================
# Variables de entorno
# ============================================================== 
REMOTE_USER="markmur88"

APP_USER="markmur88"
EMAIL_SSL="netghostx90@protonmail.com"
APP_HOME="/home/$APP_USER"
REPO_GIT="git@github.com:markmur90/api_bank_h2.git"
IP_VPS="80.78.30.242"
PORT_VPS="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
REPO_DIR="api_bank_h2"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
CLONE_PATH="$APP_HOME/$REPO_DIR"

echo "📦 Iniciando despliegue en $IP_VPS…"

# ==============================================================
# Bloque remoto: Fase 2 (markmur88 sobre VPS)
# ————————————————————————————————————————————————
# Nótese que el heredoc usa <<EOF (sin comillas) para expandir variables
# ============================================================== 
# ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e -x



cd /home/"$APP_USER"
if [ -d "$REPO_DIR" ]; then
    rm -rf "$REPO_DIR"
fi

echo "📦 Clonando repositorio en nombre de $APP_USER..."

# Clonamos como el usuario correcto, sin sudo generalizado
sudo -u "$APP_USER" git clone "$REPO_GIT" "$CLONE_PATH"

echo "✅ Repositorio clonado correctamente como $APP_USER."

# Aseguramos los permisos del contenido
sudo chown -R "$APP_USER":www-data "$CLONE_PATH"

echo "🔐 Permisos ajustados en $CLONE_PATH"

python3 -m venv ~/envAPP
source ~/envAPP/bin/activate

pip install --upgrade pip
pip install -r ~/"$REPO_DIR"/requirements.txt



sudo -u postgres psql <<SQL
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
        CREATE DATABASE $DB_NAME;
    END IF;
END
\$\$;

ALTER USER $DB_USER WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;
GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;
SQL

cd /home/"$APP_USER"/"$REPO_DIR"
find . -path "*/__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete

python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic --noinput

# bash $DP_DJ_DIR/00_09_cargar_json.sh

echo "🔧 Instalando Tor y configurando relay + servicio oculto..."

# Instalación
sudo apt-get update && sudo apt-get install -y tor

# Copiar configuración
echo "📁 Copiando configuración de torrc..."
sudo cp /home/markmur88/api_bank_h2/scripts/tor/torrc /etc/tor/torrc

# Reiniciar servicio
echo "🔁 Habilitando y reiniciando Tor..."
sudo systemctl enable tor
sudo systemctl restart tor

# Esperar creación del servicio oculto
echo "⌛ Esperando generación del servicio oculto..."
for i in {1..30}; do
  if [[ -f /var/lib/tor/hidden_service/hostname ]]; then
    echo "🧅 Servicio oculto generado:"
    sudo cat /var/lib/tor/hidden_service/hostname
    sudo chown -R markmur88 /var/lib/tor/hidden_service
    sudo chmod 750 /var/lib/tor/hidden_service
    break
  fi
  sleep 5
done

# Validación final
if [[ ! -f /var/lib/tor/hidden_service/hostname ]]; then
  echo "⚠️ El archivo hostname no fue generado. Verificá torrc y logs de Tor."
fi

# Reiniciar servicios supervisados
echo "🔄 Reiniciando servicios supervisados..."
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start coretransapi





# EOF