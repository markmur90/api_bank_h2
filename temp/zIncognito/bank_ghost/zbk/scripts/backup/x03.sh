#!/bin/bash
set -e

PROJECT_NAME="bank_ghost"
PROJECT_NAME_SOCK="ghost"
PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
VENV_DIR="$PROJECT_DIR/venv"
SOCK_FILE="$PROJECT_DIR/ghost.sock"
LOG_DIR="$PROJECT_DIR/logs"
GUNICORN_LOG="$LOG_DIR/gunicorn.log"
ERROR_LOG="$LOG_DIR/error.log"

echo "🚀 Iniciando creación de socket para Gunicorn..."
mkdir -p "$LOG_DIR"
[ -S "$SOCK_FILE" ] && rm -f "$SOCK_FILE" && echo "🗑️ Socket eliminado."
cd "$PROJECT_DIR"
echo "✅ Activando entorno virtual..."
source "$VENV_DIR/bin/activate"
echo "🔧 Exportando DJANGO_SETTINGS_MODULE..."
export DJANGO_SETTINGS_MODULE="bank_ghost.settings"
echo "🔥 Iniciando Gunicorn en $SOCK_FILE"
"$VENV_DIR/bin/gunicorn" bank_ghost.wsgi:application --chdir "$PROJECT_DIR" --bind "unix:$SOCK_FILE" --workers 3 --log-file "$GUNICORN_LOG" --error-logfile "$ERROR_LOG" &
sleep 2

if [ -S "$SOCK_FILE" ]; then
    echo "✅ Socket creado en $SOCK_FILE"
    echo "🔒 Ajustando permisos..."
    chown "$(whoami)":www-data "$SOCK_FILE"
    chmod 660 "$SOCK_FILE"
    echo "🔍 Verificando permisos finales:"
    ls -l "$SOCK_FILE"
    echo "✅ Gunicorn y socket configurados correctamente."
else
    echo "❌ No se pudo crear el socket en $SOCK_FILE"
    echo "📛 Revisa $ERROR_LOG para ver la traza de error de Gunicorn"
    exit 2
fi


# =========================== x03 ===========================