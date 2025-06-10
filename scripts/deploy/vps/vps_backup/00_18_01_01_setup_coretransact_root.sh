#!/usr/bin/env bash
set -e -x

# Auto-reinvoca con bash si no está corriendo con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

REMOTE_USER="root"

APP_USER="markmur88"
REPO_GIT="https://github.com/markmur90/api_bank_heroku.git"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
EMAIL_SSL="netghostx90@protonmail.com"
REPO_DIR="api_bank_heroku"

IP_VPS="80.78.30.242"
PORT_VPS="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"

echo "📦 Iniciando despliegue en $IP_VPS…"

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<'EOF'
set -e -x

#
# ========== FASE 1: ROOT (configuración del sistema, Nginx, Certbot, Supervisor, firewall, SSH) ==========
#

# 1. ---------------------------------------------------------
# Instalar dependencias básicas y herramientas
# -----------------------------------------------------------
apt-get update
apt-get full-upgrade -y
apt-get autoremove -y
apt-get clean

# Instalar paquetes necesarios
apt-get install -y \
    zsh git curl build-essential ufw fail2ban \
    python3 python3-pip python3-venv python3-dev libpq-dev \
    nginx certbot python3-certbot-nginx supervisor \
    libcairo2 libpango1.0-0 libpangoft2-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \
    libffi-dev shared-mime-info libjpeg-dev zlib1g-dev libxml2 libxml2-dev libxslt1-dev \
    rsync

# Cambiar shell por defecto a zsh para root (opcional)
if [ "$(which zsh)" ]; then
    chsh -s "$(which zsh)" root || true
fi

# 2. ---------------------------------------------------------
# Crear usuario no-root (si no existiera), establecer sudo nopasswd
# -----------------------------------------------------------
if ! id -u "markmur88" >/dev/null 2>&1; then
    APP_PASS="Ptf8454Jd55"
    useradd -m -s /bin/zsh "markmur88"
    echo "markmur88:$APP_PASS" | chpasswd
    usermod -aG sudo "markmur88"
    echo "markmur88 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"markmur88"
    mkdir -p /home/"markmur88"/.ssh
    cp /root/.ssh/authorized_keys /home/"markmur88"/.ssh/
    chown -R "markmur88":"markmur88" /home/"markmur88"/.ssh
    chmod 700 /home/"markmur88"/.ssh
    chmod 600 /home/"markmur88"/.ssh/authorized_keys
    echo "✅ Usuario markmur88 creado con acceso sudo y SSH configurado."
else
    echo "ℹ El usuario markmur88 ya existe."
fi

# 3. ---------------------------------------------------------
# Ajustar hostname y zona horaria
# -----------------------------------------------------------
hostnamectl set-hostname coretransapi
# (Si se necesita zona horaria específica, por ejemplo Europe/Berlin)
timedatectl set-timezone Europe/Berlin

# 4. ---------------------------------------------------------
# Configurar Supervisor para Gunicorn (sin arrancar aún)
# -----------------------------------------------------------
mkdir -p /var/log/supervisor
chown root:adm /var/log/supervisor
chmod 750 /var/log/supervisor

# Creamos un archivo base de Supervisor solo con la estructura; 
# el comando y directorio se completarán en Fase 2 (cuando el proyecto exista).
tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<SUPERVISOR
[program:coretransapi]
directory=/home/markmur88/$REPO_DIR
command=/home/markmur88/envAPP/bin/gunicorn config.wsgi:application \\
  --bind unix:/home/markmur88/$REPO_DIR/api.sock \\
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

# No arrancamos Supervisor aún; lo haremos tras Fase 2.
echo "🧭 Supervisor configurado (en modo ONDEMAND)."

# 5. ---------------------------------------------------------
# Configurar Nginx y obtener certificado SSL con Certbot (un solo paso)
# -----------------------------------------------------------

# 5.1. Creamos un solo bloque de Nginx que contemple HTTP/ACME y HTTPS posterior.
#      Al principio, solo servimos HTTP (sin SSL), para que Certbot inyecte el desafío.
tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<NGINX_BASIC
server {
    listen 80;
    server_name api.coretransapi.com;

    # Si llega tráfico a /, redirigimos a Gunicorn (puerto 8000) o a 127.0.0.1:8000
    # pero, durante el ACME challenge, Certbot usará /.well-known/acme-challenge/
    location / {
        proxy_pass http://127.0.0.1:8000;
        include proxy_params;
    }
}
NGINX_BASIC

# Activamos la configuración
ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx

# 5.2. Ejecutar Certbot con plugin Nginx:  
#       esto detectará el bloque "listen 80" y agregará automáticamente
#       los bloques SSL (listen 443 ssl) y redirecciones HTTP→HTTPS.
certbot --nginx --non-interactive --agree-tos -m "$EMAIL_SSL" -d api.coretransapi.com

# Tras certbot, Nginx ya tendrá un bloque como:
#   server { listen 80; server_name api.coretransapi.com; return 301 https://...; }
#   server { listen 443 ssl; server_name api.coretransapi.com; ... }

# Verificamos y recargamos Nginx
nginx -t
systemctl reload nginx

echo "🔐 SSL configurado y Nginx recargado con HTTPS."

# 6. ---------------------------------------------------------
# Configurar UFW (Firewall)
# -----------------------------------------------------------

# Política por defecto: denegar conexiones entrantes, permitir salientes
ufw default deny incoming
ufw default allow outgoing

# Permitir puertos esenciales
ufw allow 49222/tcp    # SSH nuevo puerto
ufw allow 22/tcp       # también permitir 22 en caso de que necesites fallback
ufw allow 80/tcp       # HTTP
ufw allow 443/tcp      # HTTPS
ufw allow from 127.0.0.1 to any port 5432    # Postgres local only
ufw allow from 127.0.0.1 to any port 8000    # Gunicorn local only (durante ACME)
ufw allow from 127.0.0.1 to any port 8011    # (ejemplo arbitrario, si tuvieras otro servicio)
ufw allow out 53       # DNS saliente
ufw allow out 123/udp  # NTP saliente
ufw allow out to any port 443 proto tcp

ufw --force enable
echo "🧱 Firewall UFW activado con reglas mínimas."

# 7. ---------------------------------------------------------
# Configurar Fail2Ban
# -----------------------------------------------------------
systemctl enable fail2ban --now
systemctl reload fail2ban
echo "🧼 Fail2Ban habilitado."

# 8. ---------------------------------------------------------
# Cambiar puerto SSH de manera segura
# -----------------------------------------------------------
# Creamos un respaldo del config original
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Comentamos cualquier línea previa de Port y añadimos el nuevo puerto
sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config || true
echo "Port 49222" >> /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Verificamos sintaxis y recargamos
sshd -t
systemctl restart sshd

echo "🔄 Puerto SSH cambiado a 49222. Confirma desde otro terminal antes de cerrar esta sesión."

# Fin Fase 1
echo "✅ Fase 1 completada. Reconéctate por el puerto 49222 para la Fase 2."
EOF

echo "👉 Ahora conéctate a $IP_VPS por SSH en el puerto 49222 para continuar con la Fase 2."
