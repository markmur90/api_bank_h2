#!/usr/bin/env bash
set -euo pipefail
USER="root"
VPS_IP="80.78.30.188"
SSH_KEY="$HOME/.ssh/vps_njalla_ed25519"
PROJECT_NAME="coretransapi"
REPO_URL="git@github.com:markmur88/api_bank_heroku.git"
DOMAIN="apih.coretransapi.com"
INITIAL_PORT=22
SSH_PORT=49222
APP_DIR="/home/$USER/$PROJECT_NAME"
VENV_DIR="$APP_DIR/venv"
ENV_FILE=".env.production"
scp -i "$SSH_KEY" -P "$INITIAL_PORT" "$SSH_KEY.pub" "$USER@$VPS_IP:/root/$PROJECT_NAME.pub"
ssh -i "$SSH_KEY" -p "$INITIAL_PORT" "$USER@$VPS_IP" <<EOF
adduser markmur88 --gecos "" --disabled-password
usermod -aG sudo markmur88
mkdir -p ~/.ssh
cat /root/$PROJECT_NAME.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
rm /root/$PROJECT_NAME.pub
apt update && apt install -y python3 python3-venv python3-pip nginx ufw fail2ban certbot python3-certbot-nginx git
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
systemctl restart sshd
ufw allow "$SSH_PORT"/tcp
ufw allow 'Nginx Full'
ufw --force enable
systemctl enable fail2ban --now
EOF
ssh -i "$SSH_KEY" -p "$SSH_PORT" "$USER@$VPS_IP" "mkdir -p $APP_DIR"
scp -i "$SSH_KEY" -P "$SSH_PORT" "$ENV_FILE" "$USER@$VPS_IP:$APP_DIR/$ENV_FILE"
ssh -i "$SSH_KEY" -p "$SSH_PORT" "$USER@$VPS_IP" <<EOF
cd $APP_DIR
if [ ! -d ".git" ]; then
git clone $REPO_URL .
else
git pull
fi
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate
pip install -r requirements.txt
deactivate
cat > /etc/systemd/system/$PROJECT_NAME\_gunicorn.socket <<EOL
[Unit]
Description=gunicorn socket for $PROJECT_NAME
[Socket]
ListenStream=/run/$PROJECT_NAME.sock
[Install]
WantedBy=sockets.target
EOL
cat > /etc/systemd/system/$PROJECT_NAME\_gunicorn.service <<EOL
[Unit]
Description=gunicorn service for $PROJECT_NAME
After=network.target
[Service]
User=$USER
Group=www-data
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/$ENV_FILE
ExecStart=$VENV_DIR/bin/gunicorn --workers 3 --bind unix:/run/$PROJECT_NAME.sock config.wsgi:application
[Install]
WantedBy=multi-user.target
EOL
systemctl daemon-reload
systemctl enable $PROJECT_NAME\_gunicorn.socket
systemctl start $PROJECT_NAME\_gunicorn.socket
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/$PROJECT_NAME <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    location / {
        return 301 https://\$host\$request_uri;
    }
}
server {
    listen 443 ssl;
    server_name $DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    location / {
        proxy_pass http://unix:/run/$PROJECT_NAME.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/$PROJECT_NAME
nginx -t
systemctl restart nginx
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m netghostx90@protonmail.com
EOF
