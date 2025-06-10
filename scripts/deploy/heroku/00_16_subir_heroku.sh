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
HEROKU_ROOT="$AP_HK_DIR"
ENV_FILE="$BASE_DIR/.env.production"
HEROKU_APP=apibank2
PEM_PATH="$BASE_DIR/schemas/keys/private_key.pem"

LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"
LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOG_DEPLOY")"

exec > >(tee -a "$LOG_FILE" "$LOG_DEPLOY") 2>&1

echo -e "\n📅 Inicio ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución."; exit 1' ERR

# Validación de Heroku CLI
command -v heroku >/dev/null || { echo "❌ Heroku CLI no está instalado."; exit 1; }

echo -e "\n🚀 Subiendo el proyecto a Heroku y GitHub..."
cd "$HEROKU_ROOT" || { echo "❌ Error al acceder a $HEROKU_ROOT"; exit 1; }

# Asegura que el remoto heroku esté configurado
if ! git remote | grep -q "^heroku$"; then
    echo -e "🔗 Agregando remoto Heroku..."
    heroku git:remote -a "$HEROKU_APP"
else
    echo -e "✅ Remoto Heroku ya configurado."
fi

echo -e "📦 Haciendo git add..."
git add --all

echo -e "📝 Commit con mensaje: $COMENTARIO_COMMIT"
git commit -m "$COMENTARIO_COMMIT" || echo "ℹ️  Sin cambios para commitear."

echo -e "🌐 Push a GitHub..."
git push origin api-bank || { echo "❌ Error al subir a GitHub"; exit 1; }

sleep 3
export HEROKU_API_KEY="HRKU-6803f1ea-fd1f-4210-a5cd-95ca7902ccf6"
echo "$HEROKU_API_KEY" | heroku auth:token | tee -a "$LOG_DEPLOY"

echo -e "☁️  Push a Heroku..."
git push heroku api-bank:main || { echo "❌ Error en deploy a Heroku"; exit 1; }

sleep 3
heroku restart --app "$HEROKU_APP"
echo -e "✅ Heroku reiniciado correctamente."

cd "$BASE_DIR"
echo -e "\n🎉 ✅ ¡Deploy completado con éxito!"
