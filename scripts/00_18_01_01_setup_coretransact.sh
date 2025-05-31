#!/usr/bin/env bash

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
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e

# === Variables (ajustables) ===
IP_VPS="80.78.30.242"
verificar_huella_ssh "$IP_VPS"
PORT_VPS="22"
REMOTE_USER="root"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
APP_USER="markmur88"
REPO_GIT="git@github.com:markmur88/coretransapi.git"

echo "📦 Instalando dependencias iniciales en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e

echo "🧱 Instalando dependencias base..."
apt-get update && apt-get full-upgrade -y && apt-get autoremove -y
apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx supervisor

echo "🧱 Activando firewall UFW..."
sudo ufw default allow incoming
sudo ufw default allow outgoing
# Reglas básicas
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 8000/tcp    # HTTPS
# sudo ufw allow 18080/tcp    # HTTPS
# sudo ufw allow 18081/tcp    # HTTPS
# sudo ufw allow 28080/tcp    # HTTPS
# sudo ufw allow 28081/tcp    # HTTPS
sudo ufw allow 49222/tcp   # HTTPS NJALLA
sudo ufw allow out to any port 443 #PUSH
# Gunicorn y PostgreSQL solo local
sudo ufw allow from 127.0.0.1 to any port 8000
sudo ufw allow from 127.0.0.1 to any port 8011
sudo ufw allow from 127.0.0.1 to any port 8001
sudo ufw allow from 127.0.0.1 to any port 5432
# Honeypot SSH
# sudo ufw allow 2222/tcp
# Supervisor local
sudo ufw allow from 127.0.0.1 to any port 9001
# Tor
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051
# # DNS y NTP salientes
sudo ufw allow out 53
sudo ufw allow out 123/udp
# # Heroku CLI saliente
# sudo ufw allow out to any port 443
# Monero (XMR)
# sudo ufw allow 18080/tcp                                     # Nodo P2P abierto
# sudo ufw allow proto tcp from 127.0.0.1 to any port 18082    # Wallet RPC local
# sudo ufw allow proto tcp from 127.0.0.1 to any port 18089:18100  # Rango wallets
# Livereload (local)
# sudo ufw allow from 127.0.0.1 to any port 35729
# Ghost API (local)
# sudo ufw allow from 127.0.0.1 to any port 5000
# Activar UFW
sudo ufw --force enable

echo "🎯 Hostname y zona horaria..."
hostnamectl set-hostname coretransapi

echo "👤 Creando usuario $APP_USER..."
useradd -m -s /bin/bash $APP_USER
usermod -aG sudo $APP_USER
echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$APP_USER
mkdir -p /home/$APP_USER/.ssh
cp /root/.ssh/authorized_keys /home/$APP_USER/.ssh/
chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
chmod 700 /home/$APP_USER/.ssh
chmod 600 /home/$APP_USER/.ssh/authorized_keys
EOF

echo "✅ Fase 1 completada. Ahora conectate por el puerto 49222 y ejecutá la fase 2."