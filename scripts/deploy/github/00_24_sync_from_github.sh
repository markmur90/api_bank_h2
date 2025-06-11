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

echo "📡 Sincronizando VPS con GitHub..."
cd ~/api_bank_h2
source ~/envAPP/bin/activate

# Verificar y stashear si hay cambios locales
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "🧠 Cambios locales detectados. Haciendo stash automático..."
    git stash pull -u -m "Stash automático antes de pull remoto"
fi

# Pull usando clave correcta
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519_heroku" git pull origin api-bank
 

echo "🔁 Actualizar Django..."
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py collectstatic --noinput

echo "🔁 Reiniciando servicios..."
sudo supervisorctl restart coretransapi

sudo systemctl reload nginx

echo "✅ Servicios reiniciados. Estado:"

echo "📋 Estado del servicio coretransapi:"
sudo supervisorctl status coretransapi
echo "📄 Últimos logs de error:"
tail -n 10 /var/log/supervisor/coretransapi.err.log