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


# if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
#     echo "🧍 Ejecutando como root. Cambiando a usuario 'markmur88'..."
    
#     # # Solicita la contraseña de sudo
#     # read -s -p "🔐 Ingresá la contraseña de 'markmur88': " SUDO_PASS
#     # echo
#     SUDO_PASS="Ptf8454Jd55"
#     # Ejecuta el script como markmur88 usando sudo con contraseña
#     echo "$SUDO_PASS" | sudo -S -u markmur88 "$0" "$@"
#     exit 0
# fi

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
verificar_huella_ssh "$IP_VPS"
# ==============================================================
# Auto-reinvoca con bash si no está corriendo con bash
# ============================================================== 
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# ==============================================================
# Variables de entorno
# ============================================================== 
REMOTE_USER="root"

APP_USER="markmur88"
REPO_GIT="https://github.com/markmur90/api_bank_h2.git"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
EMAIL_SSL="netghostx90@protonmail.com"
REPO_DIR="api_bank_h2"

IP_VPS="80.78.30.242"
PORT_VPS="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"

echo "📦 Iniciando despliegue en $IP_VPS…"

# ==============================================================
# Bloque remoto: Fase 1 (root sobre VPS)
# ————————————————————————————————————————————————
# Nótese que el heredoc usa <<EOF (sin comillas) para expandir variables
# ============================================================== 
# ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e -x

#
# ===========================
# FASE 1: ROOT (VPS Config)
# ===========================
#

# 1. ---------------------------------------------------------
# Actualizar sistema e instalar dependencias generales
# -----------------------------------------------------------
apt-get update
apt-get full-upgrade -y
apt-get autoremove -y
apt-get clean

apt-get install -y \
    zsh git curl build-essential ufw fail2ban \
    python3 python3-pip python3-venv python3-dev libpq-dev \
    nginx certbot python3-certbot-nginx supervisor \
    libcairo2 libpango1.0-0 libpangoft2-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \
    libffi-dev shared-mime-info libjpeg-dev zlib1g-dev libxml2 libxml2-dev libxslt1-dev \
    rsync

# Cambiar shell por defecto a zsh para root (opcional)
if [ "\$(which zsh)" ]; then
    chsh -s "\$(which zsh)" root || true
fi

# 2. ---------------------------------------------------------
# Crear usuario no-root (si no existe) y configurar sudoers
# -----------------------------------------------------------
# ============================================================================================================================

# 1. Crear el usuario con home y bash
useradd -m -s /bin/bash markmur88

# 2. Establecer contraseña segura
echo 'markmur88:Ptf8454Jd55' | chpasswd

# 3. Añadir al grupo sudo (en Debian/Ubuntu) o wheel (en RHEL/CentOS)
#    Debian/Ubuntu:
usermod -aG sudo markmur88
#    RHEL/CentOS:
# usermod -aG wheel markmur88

# 4. Crear sudoers personalizado SIN contraseña
printf 'markmur88 ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/markmur88

# 5. Ajustar propiedad y permisos del sudoers snippet
chown root:root /etc/sudoers.d/markmur88
chmod 440         /etc/sudoers.d/markmur88

# 6. Verificar sintaxis antes de continuar
visudo -cf /etc/sudoers.d/markmur88

# 7. Configurar SSH
mkdir -p /home/markmur88/.ssh
cp /root/.ssh/authorized_keys /home/markmur88/.ssh/authorized_keys
chown -R markmur88:markmur88 /home/markmur88/.ssh
chmod 700  /home/markmur88/.ssh
chmod 600  /home/markmur88/.ssh/authorized_keys

# 8. (Opcional, si usas SELinux) Restaurar contexto
# restorecon -Rv /home/markmur88/.ssh

# ============================================================================================================================

# 3. ---------------------------------------------------------
# Ajustar hostname y zona horaria
# -----------------------------------------------------------
hostnamectl set-hostname coretransapi
timedatectl set-timezone Europe/Berlin

# 4. ---------------------------------------------------------
# Configurar Supervisor (sin arrancar aún)
# -----------------------------------------------------------
sudo mkdir -p /var/log/supervisor
sudo chown markmur88 /var/log/supervisor
sudo chmod 750 /var/log/supervisor

sudo tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<SUPERVISOR
[program:coretransapi]
directory=/home/markmur88/api_bank_h2
command=/home/markmur88/envAPP/bin/gunicorn config.wsgi:application \\
  --bind unix:/home/markmur88/api_bank_h2/api.sock \\
  --workers 3
autostart=false
autorestart=true
umask=007
stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log
user=markmur88
group=www-data
environment=\\
  PATH="/home/markmur88/envAPP/bin",\\
  DJANGO_SETTINGS_MODULE="config.settings",\\
  DJANGO_ENV="production",\\
  DEBUG="False",\\
  ALLOWED_HOSTS="api.coretransapi.com",\\
  SECRET_KEY="MX2QfdeWkTc8ihotA_i1Hm7_4gYJQB4oVjOKFnuD6Cw",\\
  REDIRECT_URI="https://api.coretransapi.com/oauth2/callback/",\\
  ORIGIN="https://api.coretransapi.com",\\
  CLIENT_ID="7c1e2c53-8cc3-4ea0-bdd6-b3423e76adc7",\\
  CLIENT_SECRET="L88pwGelUZ5EV1YpfOG3e_r24M8YQ40-Gaay9HC4vt4RIl-Jz2QjtmcKxY8UpOWUInj9CoUILPBSF-H0QvUQqw",\\
  TOKEN_URL="https://simulator-api.db.com:443/gw/oidc/token",\\
  AUTHORIZE_URL="https://simulator-api.db.com:443/gw/oidc/authorize",\\
  OTP_URL="https://simulator-api.db.com:443/gw/dbapi/others/onetimepasswords/v2/single",\\
  AUTH_URL="https://simulator-api.db.com:443/gw/dbapi/others/transactionAuthorization/v1/challenges",\\
  API_URL="https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer",\\
  SCOPE="sepa_credit_transfers",\\
  TIMEOUT="3600",\\
  TIMEOUT_REQUEST="3600"
SUPERVISOR

echo "🧭 Supervisor preparado (autostart=false por ahora)."

# 5. ---------------------------------------------------------
# Configurar Nginx y obtener SSL con Certbot (--nginx)
# -----------------------------------------------------------

# 5.1. Definir bloque básico HTTP en Nginx (para ACME challenge)
sudo tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<NGINX_BASIC
server {
    listen 80;
    server_name api.coretransapi.com;

    # Proxy a Gunicorn (puerto 8000) — durante ACME challenge, Certbot overrideusa /.well-known
    location / {
        proxy_pass http://127.0.0.1:8000;
        include proxy_params;
    }
}
NGINX_BASIC

sudo ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl reload nginx

# 5.2. Obtener certificado SSL con Certbot + plugin Nginx
sudo certbot --nginx --non-interactive --agree-tos -m "netghostx90@protonmail.com" -d api.coretransapi.com

# Tras certbot, Nginx ya incluirá:
#   - Un bloque que redirige puertos 80→443
#   - Un bloque listen 443 ssl con fullchain.pem y privkey.pem

sudo nginx -t
sudo systemctl reload nginx

echo "🔐 SSL instalado correctamente en Nginx."

# 6. ---------------------------------------------------------
# Configurar UFW (Firewall)
# -----------------------------------------------------------



ufw allow 49222/tcp
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 127.0.0.1 to any port 5432
ufw allow from 127.0.0.1 to any port 8000
ufw allow out 53
ufw allow out 123/udp
ufw allow out 443/tcp
ufw allow from 127.0.0.1 to any port 8001
ufw allow from 127.0.0.1 to any port 8011
ufw allow from 127.0.0.1 to any port 9001
ufw allow from 127.0.0.1 to any port 9050
ufw allow from 127.0.0.1 to any port 9051
ufw allow from 127.0.0.1 to any port 9052
ufw allow from 127.0.0.1 to any port 9180




echo "🧱 UFW activado con reglas básicas."



# 8. ---------------------------------------------------------
# Cambiar puerto SSH de manera segura
# -----------------------------------------------------------
# cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# # Añadir nueva directiva de Puerto al final (y deshabilitar root login)
# grep -q "^Port 49222" /etc/ssh/sshd_config || echo "Port 49222" >> /etc/ssh/sshd_config
# sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# sshd -t
# systemctl restart sshd
# echo "🔄 SSH ahora en puerto 49222. Verifícalo en nuevo terminal antes de cerrar esta sesión."


# 7. ---------------------------------------------------------
# Configurar Fail2Ban
# -----------------------------------------------------------
systemctl enable fail2ban --now
systemctl reload fail2ban
echo "🧼 Fail2Ban habilitado."

# Fin Fase 1
echo "✅ Fase 1 completada. Reconéctate a $IP_VPS en el puerto 49222 para la Fase 2."
EOF

echo "👉 Ahora conecta por SSH al VPS en puerto 49222 para continuar con la Fase 2."
