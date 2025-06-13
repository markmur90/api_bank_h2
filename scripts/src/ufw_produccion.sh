#!/usr/bin/env bash
# === FIREWALL PARA VPS (Producción) ===

set -euo pipefail

echo -e "\n🔐 Aplicando reglas de firewall para PRODUCCIÓN..."

# Reset UFW
sudo ufw --force reset

# Reglas básicas
sudo ufw allow 22/tcp              # SSH
sudo ufw allow 80/tcp              # HTTP
sudo ufw allow 443/tcp             # HTTPS
sudo ufw allow 49222/tcp           # Admin personalizado
sudo ufw allow 9002/tcp           # Simulador
sudo ufw allow 9181/tcp           # Simulador
# sudo ufw allow 9053/tcp           # Simulador
# sudo ufw allow 9054/tcp           # Simulador
sudo ufw allow 5432/tcp           # Simulador
sudo ufw allow 8000/tcp           # Simulador



# Accesos locales a servicios (loopback)
for port in 5432 8000 8001 8011 8080 9001 9002 9100 9050 9051 9052 9053 9054 9055 9056 9180 9181; do
    sudo ufw allow from 127.0.0.1 to any port $port
done
sudo ufw allow 9181/tcp comment "Staging - Simulador Gunicorn"

# Salidas necesarias
sudo ufw allow out 53              # DNS
sudo ufw allow out 123/udp         # NTP
sudo ufw allow out to any port 443 proto tcp

# Logging
sudo ufw logging on
sudo ufw logging medium

# Reglas iptables anti-escaneo
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

# Políticas por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Activar UFW
sudo ufw --force enable

echo -e "\n✅ Reglas de firewall aplicadas para PRODUCCIÓN."
