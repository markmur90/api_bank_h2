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

SCRIPT_NAME="$(basename "$0")"

BASE_DIR="$AP_H2_DIR"
ENV_FILE="$BASE_DIR/.env.production"
HEROKU_APP="${1:-apibank2}"
PEM_PATH="$AP_H2_DIR/schemas/keys/private_key.pem"

LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"
LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/${SCRIPT_NAME%.sh}.log"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOG_DEPLOY")"

{
  echo ""
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: $SCRIPT_NAME"
  echo -e "═══════════════════════════════════════════"
  echo -e "🚀 Subiendo variables de entorno a Heroku ($HEROKU_APP)..."
} | tee -a "$LOG_FILE" "$LOG_DEPLOY"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE" "$LOG_DEPLOY"; exit 1' ERR

command -v heroku >/dev/null || { echo "❌ Heroku CLI no está instalado." | tee -a "$LOG_DEPLOY"; exit 1; }

# === Desactivamos collectstatic para evitar errores innecesarios en producción ===
echo -e "\n🔧 Desactivando collectstatic en Heroku..." | tee -a "$LOG_DEPLOY"
heroku config:set DISABLE_COLLECTSTATIC=1 --app "$HEROKU_APP" | tee -a "$LOG_DEPLOY"

# === Carga de variables desde el archivo .env.production ===
echo -e "\n📤 Cargando variables desde $ENV_FILE..." | tee -a "$LOG_DEPLOY"
[[ -f "$ENV_FILE" ]] || { echo "❌ Archivo $ENV_FILE no encontrado." | tee -a "$LOG_DEPLOY"; exit 1; }

export HEROKU_DEBUG=1
export TERM=dumb


echo -e "\n🔧 Desactivando collectstatic en Heroku..."
heroku config:set DISABLE_COLLECTSTATIC=1 --app "$HEROKU_APP"

echo -e "\n📤 Cargando variables desde $ENV_FILE..."
[[ -f "$ENV_FILE" ]] || { echo "❌ Archivo $ENV_FILE no encontrado."; exit 1; }

HEROKU_DEBUG=1
export TERM=dumb

while IFS='=' read -r key value; do
  [[ -z "${key// }" || "${key:0:1}" == "#" ]] && continue
  value="${value%\"}"
  value="${value#\"}"
  if HEROKU_DEBUG=1 TERM=dumb heroku config:set "$key=$value" --app "$HEROKU_APP" > >(grep -v 'Setting .* restarting' >> "$LOG_DEPLOY") 2>&1; then
    echo "✅ $key cargada correctamente"
  else
    echo "⚠️  Error al cargar $key"
  fi
done < "$ENV_FILE"

if [[ -f "$PEM_PATH" ]]; then
  echo -e "\n🔑 Clave privada detectada en $PEM_PATH"
  PRIVATE_KEY_B64=$(base64 -w 0 "$PEM_PATH")
  if heroku config:set PRIVATE_KEY_B64="$PRIVATE_KEY_B64" --app "$HEROKU_APP"; then
    echo "✅ Clave privada codificada subida como PRIVATE_KEY_B64"
  else
    echo "⚠️  Error al subir PRIVATE_KEY_B64"
  fi
else
  echo "⚠️  Archivo $PEM_PATH no encontrado. Saltando PRIVATE_KEY_B64."
fi

echo -e "\n📦 Total de variables cargadas: $success" | tee -a "$LOG_DEPLOY"
echo -e "✅ Finalizado correctamente.\n" | tee -a "$LOG_DEPLOY"
