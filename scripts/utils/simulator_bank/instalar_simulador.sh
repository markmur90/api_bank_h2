#!/bin/bash
set -euo pipefail

BASE_DIR="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank"
SYSTEMD_DIR="/etc/systemd/system"

echo "🚀 Iniciando instalación del Simulador Bancario..."

# 1. Copiar archivos .service
echo "🛠️ Copiando servicios systemd..."
sudo cp "$BASE_DIR/simulador_banco.service" "$SYSTEMD_DIR/"
sudo cp "$BASE_DIR/tor_simulador_onion.service" "$SYSTEMD_DIR/"

# 2. Desplegar la aplicación Django
echo "📦 Ejecutando despliegue del simulador..."
cd "$BASE_DIR"
chmod +x deploy_simulador.sh
./deploy_simulador.sh

# 3. Configurar servicio oculto de Tor
echo "🧅 Configurando servicio .onion para el simulador..."
chmod +x agregar_hidden_simulador.sh
./agregar_hidden_simulador.sh

# 4. Activar servicios
echo "🔄 Habilitando y arrancando servicios..."
sudo systemctl daemon-reload
sudo systemctl enable simulador_banco
sudo systemctl start simulador_banco

sudo systemctl enable tor_simulador_onion
sudo systemctl start tor_simulador_onion

echo "✅ Instalación completa. Verificá los logs y el archivo .onion generado."
