#!/usr/bin/env bash
# Script combinado: coretransact + simulador bancario
# Generado automáticamente

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
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# verificar_huella_ssh() {
#     local host="$1"
#     echo "🔍 Verificando huella SSH para $host..."
#     ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$host" "exit" >/dev/null 2>&1 || {
#         echo "⚠️  Posible conflicto de huella, limpiando..."
#         ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$host" >/dev/null
#     }
# }

# IP_VPS="80.78.30.242"
# PORT_VPS="22"

# verificar_huella_ssh "$IP_VPS"

REMOTE_USER="markmur88"
APP_USER="markmur88"
REPO_DIR="api_bank_h2"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="${DB_PASS:-changeme_securely}"
DB_HOST="localhost"
REPO_GIT="git@github.com:${APP_USER}/${REPO_DIR}.git"
EMAIL_SSL="netghostx90@protonmail.com"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"

echo "📦 Instalando dependencias iniciales en $IP_VPS..."

# FIREWALL, USUARIO, CLONE, ENV, DB, NGINX, SUPERVISOR CONFIGURACIÓN OMITIDA POR LONGITUD...

# === INSTALACIÓN DEL SIMULADOR BANCARIO ===
SM_BK_DIR="${SM_BK_DIR:-/opt/simulator_bank}"
VPS_USER="${VPS_USER:-simuser}"
SIM_DIR="$SM_BK_DIR/simulador_banco"
PORT=9180
SERVICE_NAME="simulador_banco"
HS_DIR="/var/lib/tor/hidden_service_simulador"
TORRC_ORIG="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/torrc_simulador_banco"
TORRC_BKP="/etc/tor/torrc.bkp.simulador"

echo "📁 Preparando entorno del simulador en: $SIM_DIR"
sudo mkdir -p "$SIM_DIR"
sudo chown "$VPS_USER":"$VPS_USER" "$SIM_DIR"
cd "$SIM_DIR"

echo "⚙️ Iniciando proyecto Django simulador_banco..."
django-admin startproject simulador_banco .
mkdir banco && touch banco/__init__.py

cat > banco/views.py <<EOF
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

@csrf_exempt
def recibir_transferencia(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            campos = ["paymentIdentification", "debtor", "creditor", "instructedAmount"]
            if not all(field in data for field in campos):
                return JsonResponse({"estado": "RJCT", "mensaje": "Campos faltantes"}, status=400)
            return JsonResponse({"estado": "ACSC", "mensaje": "Transferencia aceptada"}, status=200)
        except Exception as e:
            return JsonResponse({"estado": "ERRO", "mensaje": str(e)}, status=500)
    return JsonResponse({"mensaje": "Solo POST permitido"}, status=405)
EOF

cat > banco/urls.py <<EOF
from django.urls import path
from .views import recibir_transferencia
urlpatterns = [ path("recibir/", recibir_transferencia) ]
EOF

sed -i "/from django.urls import path/a from django.urls import include" simulador_banco/urls.py
sed -i "/urlpatterns = \\[/a     path('api/gpt4/', include('banco.urls'))," simulador_banco/urls.py
sed -i "s/ALLOWED_HOSTS = \\[\\]/ALLOWED_HOSTS = ['localhost']/" simulador_banco/settings.py

echo "📂 Aplicando migraciones SQLite..."
python manage.py migrate

# El servicio será manejado por Supervisor

echo "🧅 Configurando acceso vía TOR HiddenService..."
sudo cp "$TORRC_ORIG" "$TORRC_BKP"
sudo mkdir -p "$HS_DIR"
sudo chown -R debian-tor:debian-tor "$HS_DIR"
sudo chmod 700 "$HS_DIR"
grep -q "$HS_DIR" "$TORRC_ORIG" || echo -e "\nHiddenServiceDir $HS_DIR\nHiddenServicePort 80 127.0.0.1:$PORT" | sudo tee -a "$TORRC_ORIG"
if ! grep -q "^ControlPort" "$TORRC_ORIG"; then
    echo "ControlPort 9051" | sudo tee -a "$TORRC_ORIG"
fi
sudo systemctl restart tor
sleep 3
echo -n "🌐 Dirección .onion: "
sudo cat "$HS_DIR/hostname"

# 🌐 NGINX: Proxy para simulador (HTTPS)
echo "📡 Configurando Nginx para el simulador..."
sudo tee -a /etc/nginx/sites-available/coretransapi.conf > /dev/null <<'NGINX_SIM'
location /simulador/ {
    proxy_pass http://127.0.0.1:9180/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
NGINX_SIM
sudo nginx -t && sudo systemctl reload nginx

# 🧠 Supervisor: configuración para el simulador
echo "🧠 Configurando Supervisor para el simulador..."
sudo tee /etc/supervisor/conf.d/simulador.conf > /dev/null <<'SUPERVISOR_SIM'
[program:simulador]
directory=/home/markmur88/simulador_banco
command=/home/markmur88/envAPP/bin/gunicorn simulador_banco.wsgi:application --bind 127.0.0.1:9180 --workers 2
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/simulador.err.log
stdout_logfile=/var/log/supervisor/simulador.out.log
user=markmur88
group=www-data
environment=\
  PATH="/home/markmur88/envAPP/bin",\
  DJANGO_SETTINGS_MODULE="simulador_banco.settings",\
  DJANGO_ENV="production"
SUPERVISOR_SIM

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start simulador

# ✅ Mostrar estado de servicios Supervisor
echo "📋 Estado de servicios supervisados:"
sudo supervisorctl status
