#!/usr/bin/env bash
set -euo pipefail

### CONFIGURACIÓN ###
ENV_FILE=".env.production"
APP_NAME="apibank2"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

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
