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

### CONFIGURACIÓN ###
ENV_FILE=".env.production"
APP_NAME="apibank2"
LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"

### CABECERA ###
echo "📦 Aplicando variables de entorno a Heroku → app: $APP_NAME"
echo "🗂️  Archivo fuente: $ENV_FILE"
echo "📄 Log: $LOG_FILE"
echo "──────────────────────────────────────────────"

# Verificamos existencia
if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ No se encontró el archivo: $ENV_FILE"
    exit 1
fi

# Limpiar log anterior
> "$LOG_FILE"

# Contadores
success=0
fail=0

# Proceso de variables
while IFS= read -r line; do
    # Ignora comentarios y líneas vacías
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    # Validación básica del formato
    if [[ ! "$line" =~ ^[A-Z0-9_]+=.+$ ]]; then
        echo "⚠️  Formato inválido: $line" | tee -a "$LOG_FILE"
        ((fail++))
        continue
    fi

    # Exportación a Heroku
    if heroku config:set "$line" --app "$APP_NAME" >>"$LOG_FILE" 2>&1; then
        echo "✅ OK: $line"
        ((success++))
    else
        echo "❌ Error al aplicar: $line" | tee -a "$LOG_FILE"
        ((fail++))
    fi
done < "$ENV_FILE"

# Resumen
echo "──────────────────────────────────────────────"
echo "✅ Variables aplicadas con éxito: $success"
echo "❌ Variables con error: $fail"
echo "📋 Consulta el log detallado: $LOG_FILE"
