#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

source "$BASE_DIR/.env"

LOG_FILE="$BASE_DIR/logs/master_run.log"

log_info() { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()   { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error(){ echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

PASSPHRASE="${PASSPHRASE:-changeme123}"  # Cambia esta variable para cifrado

log_info "🚀 Subiendo Ghost al VPS..."

# Opcional: cifrar y subir con blindaje
BACKUP_DIR="$BASE_DIR/backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/ghost_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
ENC_BACKUP_FILE="$BACKUP_FILE.enc"

tar czf "$BACKUP_FILE" -C "$GHOST_ROOT" .

log_info "🔐 Cifrando backup antes de subir..."
openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASSPHRASE" -in "$BACKUP_FILE" -out "$ENC_BACKUP_FILE"

log_info "📤 Transferencia cifrada vía rsync+ssh..."
rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=yes" "$ENC_BACKUP_FILE" "$VPS_USER@$VPS_IP:$VPS_GHOST_DIR/" >> "$LOG_FILE" 2>&1

log_ok "📦 Backup cifrado transferido"

log_info "⚙️ Desencriptando y desplegando en VPS..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes "$VPS_USER@$VPS_IP" bash <<EOF
set -e
cd $VPS_GHOST_DIR
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$PASSPHRASE" -in "$(basename $ENC_BACKUP_FILE)" -out ghost_backup.tar.gz
tar xzf ghost_backup.tar.gz
rm -f ghost_backup.tar.gz "$(basename $ENC_BACKUP_FILE)"

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# systemd para ghost.service
sudo tee /etc/systemd/system/ghost.service > /dev/null <<EOL
[Unit]
Description=Gunicorn daemon for Ghost Recon
After=network.target

[Service]
User=$VPS_USER
Group=www-data
WorkingDirectory=$VPS_GHOST_DIR
ExecStart=$VPS_GHOST_DIR/venv/bin/gunicorn --workers 3 --bind unix:$VPS_GHOST_DIR/ghost.sock config.wsgi:application

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable --now ghost.service

sudo tee /etc/nginx/sites-available/ghost > /dev/null <<EOL
upstream ghost_upstream {
    server unix:$VPS_GHOST_DIR/ghost.sock;
}

server {
    listen 80;
    server_name ghost.api.coretransapi.com;

    location / {
        proxy_pass http://ghost_upstream;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/ghost /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
EOF

log_ok "✅ Deploy Ghost en VPS completado."
