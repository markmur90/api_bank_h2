#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

source "$BASE_DIR/.env"

LOG_FILE="$BASE_DIR/logs/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

PASSPHRASE="${PASSPHRASE:-"##_//Ptf8454Jd55\\_##"}"

log_info "🚀 Subiendo api_bank_h2 al VPS..."

BACKUP_DIR="$BASE_DIR/backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/api_bank_h2_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
ENC_BACKUP_FILE="$BACKUP_FILE.enc"

tar czf "$BACKUP_FILE" -C "$PROJECT_ROOT" .

log_info "🔐 Cifrando backup antes de subir..."
openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASSPHRASE" -in "$BACKUP_FILE" -out "$ENC_BACKUP_FILE"

log_info "📤 Transferencia cifrada vía rsync+ssh..."
rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=yes" "$ENC_BACKUP_FILE" "root@$VPS_IP:$VPS_API_DIR/" >> "$LOG_FILE" 2>&1

log_ok "📦 Backup cifrado transferido"

log_info "👤 Preparando usuario y entorno remoto..."

# Bloque root: crear usuario y preparar directorio seguro
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes root@$VPS_IP bash <<EOF
set -e

if ! id "markmur88" &>/dev/null; then
    echo "➕ Creando usuario 'markmur88' con sudo..."
    adduser --disabled-password --gecos "" markmur88
    usermod -aG sudo markmur88
    mkdir -p /home/markmur88/api_bank_h2
    chown -R markmur88:www-data /home/markmur88/api_bank_h2
    echo "✅ Usuario y directorio creados."
else
    echo "✅ Usuario 'markmur88' ya existe."
fi
EOF

log_info "⚙️ Desencriptando y desplegando como markmur88..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes markmur88@$VPS_IP bash <<EOF
set -e
cd "$VPS_API_DIR"

openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$PASSPHRASE" -in "$(basename $ENC_BACKUP_FILE)" -out api_bank_h2_backup.tar.gz
tar xzf api_bank_h2_backup.tar.gz
rm -f api_bank_h2_backup.tar.gz "$(basename $ENC_BACKUP_FILE)"

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

mkdir -p "$VPS_API_DIR/servers/gunicorn"

cat > "$VPS_API_DIR/servers/gunicorn/gunicorn.socket" <<EOL
[Unit]
Description=Gunicorn Socket for api_bank_h2
PartOf=gunicorn.service

[Socket]
ListenStream=$VPS_API_DIR/servers/gunicorn/api.sock
SocketMode=0660
SocketUser=www-data
SocketGroup=www-data

[Install]
WantedBy=sockets.target
EOL

cat > "$VPS_API_DIR/servers/gunicorn/gunicorn.service" <<EOL
[Unit]
Description=Gunicorn Daemon for api_bank_h2
Requires=gunicorn.socket
After=network.target

[Service]
User=markmur88
Group=www-data
WorkingDirectory=$VPS_API_DIR
Environment="PATH=$VPS_API_DIR/venv/bin"
ExecStart=$VPS_API_DIR/venv/bin/gunicorn \\
          --access-logfile - \\
          --workers 3 \\
          --bind unix:$VPS_API_DIR/servers/gunicorn/api.sock \\
          config.wsgi:application

[Install]
WantedBy=multi-user.target
EOL

sudo cp "$VPS_API_DIR/servers/gunicorn/gunicorn."* /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now gunicorn.socket
sudo systemctl start gunicorn.service

# Configuración HTTPS con redirección desde HTTP
sudo rm -f /etc/nginx/sites-enabled/api_bank_h2
sudo tee /etc/nginx/sites-available/api.coretransapi.com > /dev/null <<EOL
server {
    listen 80;
    server_name api.coretransapi.com;

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://unix:$VPS_API_DIR/servers/gunicorn/api.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/api.coretransapi.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
EOF

log_ok "✅ Deploy api_bank_h2 en VPS completado."
