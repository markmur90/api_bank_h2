#!/usr/bin/env bash
set -euo pipefail

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Reglas básicas
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 8000/tcp    # HTTPS
sudo ufw allow 18080/tcp    # HTTPS
sudo ufw allow 18081/tcp    # HTTPS
sudo ufw allow 28080/tcp    # HTTPS
sudo ufw allow 28081/tcp    # HTTPS
sudo ufw allow 49222/tcp   # HTTPS NJALLA
sudo ufw allow out to any port 443 #PUSH
# Gunicorn y PostgreSQL solo local
sudo ufw allow from 127.0.0.1 to any port 8000
sudo ufw allow from 127.0.0.1 to any port 8011
sudo ufw allow from 127.0.0.1 to any port 8001
sudo ufw allow from 127.0.0.1 to any port 5432
# Honeypot SSH
sudo ufw allow 2222/tcp
# Supervisor local
sudo ufw allow from 127.0.0.1 to any port 9001
# Tor
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051
# DNS y NTP salientes
sudo ufw allow out 53
sudo ufw allow out 123/udp
# Heroku CLI saliente
sudo ufw allow out to any port 443
# Monero (XMR)
sudo ufw allow 18080/tcp                                     # Nodo P2P abierto
sudo ufw allow proto tcp from 127.0.0.1 to any port 18082    # Wallet RPC local
sudo ufw allow proto tcp from 127.0.0.1 to any port 18089:18100  # Rango wallets
# Livereload (local)
sudo ufw allow from 127.0.0.1 to any port 35729
# Ghost API (local)
sudo ufw allow from 127.0.0.1 to any port 5000
# Activar UFW
sudo ufw --force enable
echo -e "\033[7;30m🔐 Reglas de UFW aplicadas con éxito.\033[0m"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""