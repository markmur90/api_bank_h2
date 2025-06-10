#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Iniciando setup de entorno STAGING..."

# Variables
USER="staging_markmur"
APP_DIR="/home/$USER/api_bank_staging"
VENV_DIR="/home/$USER/envAPP_staging"
LOG_DIR="/home/$USER/logs"
CONFIG_DIR="/home/$USER/config"

# Crear estructura de directorios
mkdir -p "$APP_DIR" "$VENV_DIR" "$LOG_DIR" "$CONFIG_DIR"

# Clonar repositorio (rama staging)
git clone -b staging https://github.com/markmur90/api_bank_heroku.git "$APP_DIR"

# Crear y activar entorno virtual
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# Instalar dependencias
pip install --upgrade pip
pip install -r "$APP_DIR/requirements.txt"

# Copiar configs al VPS
cp supervisor_staging.conf "$CONFIG_DIR/"
cp torrc_staging "$CONFIG_DIR/"
cp gunicorn_staging.conf.py "$APP_DIR/config/"
cp .env.staging "$APP_DIR/"

# Crear data directory para Tor
mkdir -p /home/$USER/tor_data_staging/hidden_service
chown -R $USER:$USER /home/$USER/tor_data_staging

# Iniciar supervisord
supervisord -c "$CONFIG_DIR/supervisor_staging.conf"

echo "✅ Despliegue STAGING completado. Revisá los logs en $LOG_DIR"