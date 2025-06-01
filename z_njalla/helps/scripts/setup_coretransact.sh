#!/bin/bash

set -e
echo "🔐 Iniciando configuración básica para VPS: coretransapi"

# Parámetros
USER=root
IP_VPS="80.78.30.242"
CLAVE_SSH="$HOME/.ssh/vps_njalla_nueva"

# 1. Subir clave pública SSH
echo "📤 Subiendo clave SSH..."
scp -i "$CLAVE_SSH" ~/.ssh/vps_njalla_nueva.pub $USER@$IP_VPS:/root/coretransapi.pub

# 2. Configurar clave en el VPS
ssh -i "$CLAVE_SSH" $USER@$IP_VPS <<'EOF'
    echo "📎 Aplicando clave pública a authorized_keys..."
    mkdir -p ~/.ssh
    cat ~/coretransapi.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    rm ~/coretransapi.pub

    echo "🧱 Activando firewall UFW..."
    apt update && apt install ufw -y
    ufw allow OpenSSH
    ufw --force enable

    echo "🔄 Cambiando puerto SSH..."
    PORT=49222
    sed -i "s/^#Port 22/Port $PORT/" /etc/ssh/sshd_config
    sed -i "s/^PermitRootLogin yes/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
    systemctl restart sshd
    echo "✅ SSH configurado en puerto $PORT"

    echo "🎯 Hostname y entorno inicial..."
    hostnamectl set-hostname coretransapi
    echo "coretransapi" > /etc/hostname

    echo "🌍 Zona horaria..."
    timedatectl set-timezone Europe/Madrid

    adduser markmur88
    usermod -aG sudo markmur88
    
    echo "🧼 Limpieza y seguridad básica..."
    apt install fail2ban -y
    systemctl enable fail2ban --now
EOF

echo "✅ VPS coretransapi configurado correctamente."
echo "🛡️ Puedes conectarte con: ssh -i $CLAVE_SSH -p 49222 root@IP_DEL_VPS"
