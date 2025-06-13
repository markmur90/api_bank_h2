#!/usr/bin/env bash
# === FIREWALL PARA DESARROLLO LOCAL ===

set -euo pipefail

echo -e "\n🧪 Aplicando reglas de firewall para DESARROLLO LOCAL..."

# Reset UFW
sudo ufw --force reset

# Reglas mínimas necesarias para desarrollo
sudo ufw allow 22/tcp              # SSH
sudo ufw allow 80/tcp              # HTTP
sudo ufw allow 443/tcp             # HTTPS
sudo ufw allow 8000/tcp            # Django dev server
sudo ufw allow 5432/tcp            # PostgreSQL local
sudo ufw allow 8443/tcp comment "SSL certs"           # PostgreSQL local

sudo ufw allow 9051/tcp comment "Tor CP"
sudo ufw allow 9181/tcp comment "Sim local"
sudo ufw allow 9055/tcp comment "Tor SP Sim"
sudo ufw allow 9056/tcp comment "Tor CP Sim"
sudo ufw allow 9002/tcp comment "Sup Hd Sim"
sudo ufw allow 9100/tcp comment "Sup Sim"

sudo ufw allow 8001/tcp comment "Extra"
sudo ufw allow 8080/tcp comment "Extra"
sudo ufw allow 9001/tcp comment "Extra"
sudo ufw allow 9002/tcp comment "Extra"
sudo ufw allow 8001/tcp comment "Extra"
sudo ufw allow 9050/tcp comment "Extra"
sudo ufw allow 9052/tcp comment "Extra"
sudo ufw allow 9053/tcp comment "Extra"
sudo ufw allow 9054/tcp comment "Extra"
sudo ufw allow 9055/tcp comment "Extra"
sudo ufw allow 9056/tcp comment "Extra"
sudo ufw allow 9180/tcp comment "Extra"

# Salida libre para desarrollo
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Logging opcional
sudo ufw logging off

# Activar UFW
sudo ufw --force enable

echo -e "\n✅ Reglas de firewall aplicadas para DESARROLLO LOCAL."
