#!/usr/bin/env bash
set -e -x

# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
LOG_DIR="$SCRIPTS_DIR/logs/00_18_05_deploy_update"

mkdir -p "$LOG_DIR"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME%.sh}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# === Parámetros ===
IP_VPS="80.78.30.242"
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-$IP_VPS}"
SSH_KEY="${3:-/home/markmur88/.ssh/vps_njalla_nueva}"
PROYECTO_DIR="/home/$VPS_USER/api_bank_heroku"
VENV_DIR="/home/$VPS_USER/envAPP"

echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "🔁 Ejecutando actualización remota en $VPS_USER@$VPS_IP"
echo ""

# === Función para reporte de estado ===
reporte_estado() {
    local status=$1
    local mensaje=$2
    if [ "$status" -eq 0 ]; then
        echo "✅ $mensaje completado correctamente."
    else
        echo "❌ Error en: $mensaje"
    fi
}

# === Bloque remoto ===
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" bash <<'EOF'
set -e

reporte_estado() {
    local status=$1
    local mensaje=$2
    if [ "$status" -eq 0 ]; then
        echo "✅ $mensaje completado correctamente."
    else
        echo "❌ Error en: $mensaje"
    fi
}


echo ""
echo "🐍 Activando entorno virtual..."
source /home/markmur88/envAPP/bin/activate
pip install -r /home/markmur88/api_bank_h2/requirements.txt
reporte_estado $? "Activación de entorno virtual"
sleep 2
echo ""
echo "📂 Ejecutando restore_and_upload_force.sh..."
cd /home/markmur88/api_bank_heroku
bash restore_and_upload_force.sh
reporte_estado $? "restore_and_upload_force.sh"
sleep 2

echo ""
echo "⚙️ Ejecutando migraciones..."
python manage.py migrate
reporte_estado $? "Migraciones"
sleep 2

echo ""
echo "🎨 Recolectando archivos estáticos..."
python manage.py collectstatic --noinput
reporte_estado $? "Recolección de estáticos"
sleep 2

echo ""
echo "🧠 Reiniciando coretransapi via Supervisor..."
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart all
reporte_estado $? "Reinicio Supervisor"
sleep 2

echo ""
echo "🌐 Verificando configuración de Nginx..."
sudo nginx -t
reporte_estado $? "Chequeo configuración Nginx"
sleep 2

echo ""
echo "♻️ Recargando Nginx y PostgreSQL..."
sudo systemctl reload nginx
sudo systemctl restart nginx
sudo systemctl restart postgresql
reporte_estado $? "Recarga Nginx y PostgreSQL"
sleep 2

echo ""
echo "📋 **RESUMEN FINAL EN VPS**"
echo "🟢 Verificación final de servicios completada."
sleep 2

sudo bash /home/markmur88/api_bank_h2/scripts/src/ufw_produccion.sh

EOF

echo ""
echo "📋 **RESUMEN FINAL LOCAL**"
echo "🟢 Deploy remoto completado. Log en: $LOG_FILE"
