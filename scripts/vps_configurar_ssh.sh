#!/bin/bash
set -e

echo "🔁 Configurando SSH y firewall..."
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw allow 49222
ufw --force enable

sed -i 's/^#Port 22/Port 22\nPort 49222/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd
