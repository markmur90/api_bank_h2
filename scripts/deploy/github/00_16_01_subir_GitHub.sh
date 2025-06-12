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

: "${COMENTARIO_COMMIT:?❌ Faltó COMENTARIO_COMMIT}"

SCRIPT_NAME="$(basename "$0")"

BASE_DIR="$AP_H2_DIR"
HEROKU_ROOT="$AP_H2_DIR"
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



echo -e "\n🚀 Subiendo el proyecto a Heroku y GitHub..."
cd "$HEROKU_ROOT" || { echo "❌ Error al acceder a $HEROKU_ROOT"; exit 1; }

# git fetch origin
# git reset --hard origin/main


echo -e "📦 Haciendo git add..."
git add --all

echo -e "📝 Commit con mensaje: $COMENTARIO_COMMIT"
git commit -m "$COMENTARIO_COMMIT" || echo "ℹ️  Sin cambios para commitear."

echo -e "🌐 Push a GitHub..."
git push -u origin main || { echo "❌ Error al subir a GitHub"; exit 1; }

# 📝 Guardar histórico en formato Markdown
COMMIT_LOG="$SCRIPTS_DIR/logs/commits_hist.md"
mkdir -p "$(dirname "$COMMIT_LOG")"

# Agregar encabezado si el archivo está vacío o no existe
if [ ! -s "$COMMIT_LOG" ]; then
    echo -e "| Fecha                | Mensaje de commit                          |\n|----------------------|----------------------------------------------|" > "$COMMIT_LOG"
fi

# Añadir entrada nueva
echo "| $(date '+%Y-%m-%d %H:%M:%S') | ${COMENTARIO_COMMIT//|/–} |" >> "$COMMIT_LOG"



cd "$BASE_DIR"
echo -e "\n🎉 ✅ ¡Puss a GitHub completo!"

echo ""
echo "📥 Actualizando carpeta..."

bash ~/api_bank_h2/scripts/deploy/vps/sync_dir.sh
