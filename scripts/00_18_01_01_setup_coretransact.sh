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
APP_USER="deploy"
REPO_GIT="git@github.com:markmur88/coretransapi.git"

echo "📦 Instalando dependencias iniciales en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e

echo "🧱 Instalando dependencias base..."
apt update && apt upgrade -y
apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx supervisor

echo "🧱 Activando firewall UFW..."
ufw --force enable
ufw start
echo "🔓 Abriendo puertos necesarios..."
PORTS=(22 80 443 5432 8000 9001 9050 9051 53 123 49222)
for PORT in "${PORTS[@]}"; do
    ufw allow "$PORT"
done
ufw allow OpenSSH
ufw --force reload

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