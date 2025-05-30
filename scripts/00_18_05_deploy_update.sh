#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/00_18_05_deploy_update/00_18_05_deploy_update.log"
PROCESS_LOG="$SCRIPT_DIR/logs/00_18_05_deploy_update/process_00_18_05_deploy_update.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/00_18_05_deploy_update_.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PROCESS_LOG")"
mkdir -p "$(dirname "$LOG_DEPLOY")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR



#!/bin/bash

set -e
echo "🚀 Iniciando actualización incremental para coretransapi"

MARK=markmur88
DIR_USR="/home/$MARK"
PROYECTO_DIR="$DIR_USR/coretransapi"
VENV_DIR="$DIR_USR/envAPP"

echo "📥 Actualizando repositorio..."
cd $PROYECTO_DIR
sudo -u $MARK git pull

echo "🐍 Activando entorno virtual..."
source $VENV_DIR/bin/activate

echo "📦 Instalando nuevas dependencias (si hay)..."
pip install -r requirements.txt

echo "⚙️ Ejecutando migraciones..."
python manage.py migrate

echo "🎨 Recolectando archivos estáticos..."
python manage.py collectstatic --noinput

echo "🧠 Reiniciando procesos en Supervisor..."
supervisorctl restart coretransapi

echo "🌐 Recargando Nginx y verificando..."
nginx -t && systemctl reload nginx

echo "📝 Últimos logs