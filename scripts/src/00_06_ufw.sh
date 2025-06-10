#!/usr/bin/env bash
# === FIREWALL PARA DESARROLLO LOCAL ===

set -euo pipefail

echo -e "\n🧪 Aplicando reglas de firewall para DESARROLLO LOCAL..."

# Reset UFW
sudo ufw --force reset

# Reglas mínimas necesarias para desarrollo
sudo ufw allow 22/tcp              # SSH (opcional si usás VSCode Remote)
sudo ufw allow 8000/tcp            # Django dev server
sudo ufw allow 5432/tcp            # PostgreSQL local
sudo ufw allow 9181/tcp comment "Simulador local"

# Salida libre para desarrollo
sudo ufw default allow outgoing
sudo ufw default allow incoming  # No bloquear cosas como Docker u otros servicios locales

# Logging opcional
sudo ufw logging off

# Activar UFW
sudo ufw --force enable

echo -e "\n✅ Reglas de firewall aplicadas para DESARROLLO LOCAL."
