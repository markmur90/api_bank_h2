#!/bin/bash
set -euo pipefail

echo "🌐 Configurando entorno completo para VPS: coretransapi"

# === Variables ===
USUARIO="markmur88"
PROYECTO="api_bank_h2"
REPO_URL="git@github.com:markmur88/api_bank_h2.git"
PROYECTO_DIR="/home/$USUARIO/Documentos/GitHub/$PROYECTO"
VENV_DIR="/home/$USUARIO/Documentos/Entorno/venvAPI"
SSH_KEY="/root/.ssh/authorized_keys"
PORT_SSH=49222

# === Crear usuario si no existe ===
id "$USUARIO" &>/dev/null || adduser --disabled-password --gecos "" "$USUARIO"
usermod -aG sudo "$USUARIO"

# === Actualizar sistema e instalar dependencias ===
apt update && apt upgrade -y
apt install -y git python3 python3-venv python3-pip postgresql postgresql-contrib nginx ufw supervisor unzip curl net-tools

# === Configuración SSH segura ===
sed -i "s/^#Port 22/Port $PORT_SSH/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
systemctl restart sshd

# === Configuración UFW básica ===
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$PORT_SSH"/tcp
ufw allow 80,443,8000/tcp
ufw --force enable

# === Clonar proyecto ===
mkdir -p "/home/$USUARIO/Documentos/GitHub"
chown "$USUARIO":"$USUARIO" "/home/$USUARIO/Documentos/GitHub"
sudo -u "$USUARIO" git clone "$REPO_URL" "$PROYECTO_DIR"

# === Crear entorno virtual y activar dependencias ===
mkdir -p "$VENV_DIR"
sudo -u "$USUARIO" python3 -m venv "$VENV_DIR"
sudo -u "$USUARIO" "$VENV_DIR/bin/pip" install --upgrade pip
sudo -u "$USUARIO" "$VENV_DIR/bin/pip" install -r "$PROYECTO_DIR/requirements.txt"

# === Migraciones iniciales y collectstatic ===
cd "$PROYECTO_DIR"
sudo -u "$USUARIO" "$VENV_DIR/bin/python" manage.py migrate
sudo -u "$USUARIO" "$VENV_DIR/bin/python" manage.py collectstatic --noinput || true

# === Configuración Gunicorn ===
cat >/etc/systemd/system/gunicorn.service <<EOF
[Unit]
Description=Gunicorn daemon for $PROYECTO
After=network.target

[Service]
User=$USUARIO
Group=www-data
WorkingDirectory=$PROYECTO_DIR
ExecStart=$VENV_DIR/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/gunicorn.sock config.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# === Configuración Nginx ===
cat >/etc/nginx/sites-available/$PROYECTO <<EOF
server {
    listen 80;
    server_name api.coretransapi.com;

    location / {
        proxy_pass http://unix:/run/gunicorn.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/$PROYECTO /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# === Activar Gunicorn ===
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now gunicorn

# === Mensaje final ===
echo "✅ VPS coretransapi configurado exitosamente."
echo "🌐 Visita: http://api.coretransapi.com"
echo "🔐 Conéctate con: ssh -i ~/.ssh/vps_njalla_ed25519 -p $PORT_SSH root@80.78.30.188"
