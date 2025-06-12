#!/bin/bash
set -e

# CONFIG
VPS_USER="markmur88"
VPS_HOST="80.78.30.242"
VPS_DIR="/home/markmur88/api_bank_h2"
LOCAL_JSON_SCRIPT="00_09_cargar_json.sh"

echo "==> 1. Subiendo a GitHub..."
bash 00_16_01_subir_GitHub.sh

echo "==> 2. Conectando al VPS y actualizando repo..."
ssh ${VPS_USER}@${VPS_HOST} "bash ${VPS_DIR}/00_18_05_deploy_update.sh"

echo "==> 3. Ejecutando limpieza/sync..."
ssh ${VPS_USER}@${VPS_HOST} "bash ${VPS_DIR}/vps_sync_clean.sh"

echo "==> 4. Copiando script de carga JSON al VPS..."
scp ${LOCAL_JSON_SCRIPT} ${VPS_USER}@${VPS_HOST}:${VPS_DIR}/

echo "==> 5. Ejecutando carga de JSON en VPS..."
ssh ${VPS_USER}@${VPS_HOST} "bash ${VPS_DIR}/00_09_cargar_json.sh"

echo "✅ Despliegue completo."
