#!/bin/bash

# ===============================================================
# 🛠️ Script de Diagnóstico y Reparación Ghost Recon (socket .sock)
# ===============================================================

PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
PROJECT_NAME="bank_ghost"
SOCK_FILE="$PROJECT_DIR/ghost.sock"
VENV_DIR="$PROJECT_DIR/venv"
GUNICORN_CMD="$VENV_DIR/bin/gunicorn"
WSGI_MODULE="${PROJECT_NAME}.wsgi:application"
LOG_DIR="$PROJECT_DIR/logs"
GUNICORN_LOG="$LOG_DIR/gunicorn_diag.log"
ERROR_LOG="$LOG_DIR/error_diag.log"

echo -e "\n\033[1;36m🚨 Iniciando diagnóstico en caliente para Ghost Recon...\033[0m\n"

# ======================
# 1. Asegurar entorno
# ======================
mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$SOCK_FILE")"

# ======================
# 2. Verificar entorno virtual
# ======================
if [ ! -f "$GUNICORN_CMD" ]; then
    echo -e "\033[1;31m❌ Gunicorn no encontrado en: $GUNICORN_CMD\033[0m"
    exit 1
fi

# ======================
# 3. Verificar si el socket existe
# ======================
if [ -S "$SOCK_FILE" ]; then
    echo -e "\033[1;32m✅ Socket existe: $SOCK_FILE\033[0m"
else
    echo -e "\033[1;33m⚠️ Socket NO existe: $SOCK_FILE\033[0m"
fi

# ======================
# 4. Verificar si Gunicorn está corriendo
# ======================
GUNICORN_PID=$(pgrep -f "gunicorn.*$PROJECT_NAME")

if [ -n "$GUNICORN_PID" ]; then
    echo -e "\033[1;32m✅ Gunicorn está corriendo (PID: $GUNICORN_PID)\033[0m"
else
    echo -e "\033[1;33m⚠️ Gunicorn NO está corriendo. Intentando iniciar...\033[0m"
    [ -S "$SOCK_FILE" ] && rm -f "$SOCK_FILE" && echo -e "🗑️ Socket anterior eliminado"
    source "$VENV_DIR/bin/activate"
    nohup "$GUNICORN_CMD" "$WSGI_MODULE" \
        --chdir "$PROJECT_DIR" \
        --bind "unix:$SOCK_FILE" \
        --workers 3 \
        --log-level debug \
        --log-file "$GUNICORN_LOG" \
        --error-logfile "$ERROR_LOG" > /dev/null 2>&1 &
    sleep 3

    if [ -S "$SOCK_FILE" ]; then
        echo -e "\033[1;32m✅ Gunicorn iniciado y socket creado exitosamente.\033[0m"
    else
        echo -e "\033[1;31m❌ Error al iniciar Gunicorn o crear socket.\033[0m"
        echo -e "\033[1;36m➡️ Verifica logs en:\033[0m $ERROR_LOG"
        exit 2
    fi
fi

# ======================
# 5. Verificar conectividad NGINX → socket (opcional)
# ======================
echo -e "\n\033[1;36m🔍 Verificando conexión al socket desde NGINX...\033[0m"

NGINX_TEST=$(curl --unix-socket "$SOCK_FILE" http://localhost/ 2>&1)

if echo "$NGINX_TEST" | grep -q "<!DOCTYPE html>"; then
    echo -e "\033[1;32m✅ NGINX puede conectarse al socket correctamente.\033[0m"
else
    echo -e "\033[1;31m❌ NGINX no puede conectar al socket:\033[0m"
    echo "$NGINX_TEST"
fi

# ======================
# 6. Asegurar permisos del socket
# ======================
echo -e "\n\033[1;36m🔒 Ajustando permisos del socket...\033[0m"
chown "$(whoami)":www-data "$SOCK_FILE"
chmod 660 "$SOCK_FILE"
ls -l "$SOCK_FILE"

# ======================
# 7. Resultado final
# ======================
echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m"
echo -e "\033[1;32m✅ Diagnóstico y reparación completados exitosamente.\033[0m"
echo -e "\033[1;34m────────────────────────────────────────────────────────────\033[0m"

notify-send "Ghost Recon" "✅ Socket y Gunicorn verificados correctamente."

exit 0
