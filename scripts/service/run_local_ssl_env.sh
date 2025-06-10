#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

echo "🔐 Activando entorno virtual..."
source "/home/markmur88/Documentos/Entorno/envAPP/bin/activate"

echo "🌍 Estableciendo entorno local HTTPS con certificados autofirmados..."

PROJECT_DIR="$AP_H2_DIR"
cd "$PROJECT_DIR"

CERT_DIR="$PROJECT_DIR/certs"
CERT_CRT="$CERT_DIR/desarrollo.crt"
CERT_KEY="$CERT_DIR/desarrollo.key"

if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    echo "⚠️ Certificados autofirmados no encontrados, generando..."
    mkdir -p "$CERT_DIR"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_KEY" -out "$CERT_CRT" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=API Bank Dev/OU=IT/CN=0.0.0.0"
fi

echo "🚀 Ejecutando Django en modo SSL con runsslserver..."
python manage.py runsslserver --certificate "$CERT_CRT" --key "$CERT_KEY"
