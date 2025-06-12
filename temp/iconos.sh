#!/usr/bin/env bash
set -euo pipefail

PROMPT_MODE=true
OMIT_SYNC_REMOTE_DB=false
OMIT_HEROKU=false
OMIT_GUNICORN=false
OMIT_CLEAN=false
OMIT_JSON_LOCAL=false
OMIT_JSON_WEB=false
OMIT_SYNC_LOCAL=false
OMIT_ZIP_SQL=false
OMIT_MAC=false
OMIT_LOAD_LOCAL=false
OMIT_LOAD_WEB=false
OMIT_USER=false

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
BACKUP_DIR="$HOME/Documentos/GitHub/backup/"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
VENV_PATH="$HOME/Documentos/Entorno/envAPP"
INTERFAZ="wlan0"

DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="0.0.0.0"

### === OPCIONES DISPONIBLES PARA ./01_full.sh === ###
echo "🟢 Iniciando: OPCIONES DISPONIBLES PARA ./01_full.sh"

# -a  --all                Ejecuta todo sin confirmaciones interactivas
# -s  --step               Modo paso a paso (requiere confirmar cada paso)
# -B  --omit-bdd           Omite sincronización de la base de datos remota
# -H  --omit-heroku        Omite sincronización o deploy en Heroku
# -G  --omit-gunicorn      Omite reinicio del servidor Gunicorn
# -L  --omit-load-local    Omite cargar JSON locales en la base de datos
# -W  --omit-load-web      Omite cargar JSON desde endpoints web
# -J  --omit-json-local    Omite descarga de JSON locales
# -X  --omit-json-web      Omite descarga de JSON desde API externa
# -C  --omit-clean         Omite limpieza de archivos y base de datos
# -Z  --omit-zip           Omite comprimir archivos SQL
# -M  --omit-mac           Omite acciones específicas para macOS
# -U  --omit-user          Omite creación de usuario y superusuario

echo "✅ Finalizado: OPCIONES DISPONIBLES PARA ./01_full.sh"

### === ACTIVAR ENTORNO VIRTUAL === ###
echo "🟢 Iniciando: ACTIVAR ENTORNO VIRTUAL"

source "$VENV_PATH/bin/activate"

echo "✅ Finalizado: ACTIVAR ENTORNO VIRTUAL"

### === VERIFICACIÓN DE INTERNET === ###
echo "🟢 Iniciando: VERIFICACIÓN DE INTERNET"

ping -c 1 google.com > /dev/null

echo "✅ Finalizado: VERIFICACIÓN DE INTERNET"

### === DESCARGAR JSON LOCALES === ###
echo "🟢 Iniciando: DESCARGAR JSON LOCALES"

if [ "$OMIT_JSON_LOCAL" = false ]; then
    python "$PROJECT_ROOT/manage.py" descargar_json_local
fi

echo "✅ Finalizado: DESCARGAR JSON LOCALES"

### === DESCARGAR JSON DESDE API === ###
echo "🟢 Iniciando: DESCARGAR JSON DESDE API"

if [ "$OMIT_JSON_WEB" = false ]; then
    python "$PROJECT_ROOT/manage.py" descargar_json_web
fi

echo "✅ Finalizado: DESCARGAR JSON DESDE API"

### === LIMPIEZA Y RESETEO === ###
echo "🟢 Iniciando: LIMPIEZA Y RESETEO"

if [ "$OMIT_CLEAN" = false ]; then
    python "$PROJECT_ROOT/manage.py" limpiar_todo
fi

echo "✅ Finalizado: LIMPIEZA Y RESETEO"

### === CARGA DE JSON LOCALES === ###
echo "🟢 Iniciando: CARGA DE JSON LOCALES"

if [ "$OMIT_LOAD_LOCAL" = false ]; then
    python "$PROJECT_ROOT/manage.py" cargar_json_local
fi

echo "✅ Finalizado: CARGA DE JSON LOCALES"

### === CARGA DE JSON WEB === ###
echo "🟢 Iniciando: CARGA DE JSON WEB"

if [ "$OMIT_LOAD_WEB" = false ]; then
    python "$PROJECT_ROOT/manage.py" cargar_json_web
fi

echo "✅ Finalizado: CARGA DE JSON WEB"

### === SINCRONIZAR BASE DE DATOS LOCAL === ###
echo "🟢 Iniciando: SINCRONIZAR BASE DE DATOS LOCAL"

if [ "$OMIT_SYNC_LOCAL" = false ]; then
    python "$PROJECT_ROOT/manage.py" sincronizar_local
fi

echo "✅ Finalizado: SINCRONIZAR BASE DE DATOS LOCAL"

### === CREAR USUARIO === ###
echo "🟢 Iniciando: CREAR USUARIO"

if [ "$OMIT_USER" = false ]; then
    python "$PROJECT_ROOT/manage.py" crear_usuario --username admin --email admin@example.com
fi

echo "✅ Finalizado: CREAR USUARIO"

### === COMPRIMIR SQL === ###
echo "🟢 Iniciando: COMPRIMIR SQL"

if [ "$OMIT_ZIP_SQL" = false ]; then
    zip -j "$BACKUP_DIR/dump.zip" "$BACKUP_DIR"/*.sql
fi

echo "✅ Finalizado: COMPRIMIR SQL"

### === ACCIONES ESPECÍFICAS PARA MAC === ###
echo "🟢 Iniciando: ACCIONES ESPECÍFICAS PARA MAC"

if [ "$OMIT_MAC" = false ]; then
    echo "Nada por hacer para macOS por ahora"
fi

echo "✅ Finalizado: ACCIONES ESPECÍFICAS PARA MAC"

### === SINCRONIZAR BASE DE DATOS REMOTA === ###
echo "🟢 Iniciando: SINCRONIZAR BASE DE DATOS REMOTA"

if [ "$OMIT_SYNC_REMOTE_DB" = false ]; then
    pg_restore -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" "$BACKUP_DIR/dump.sql"
fi

echo "✅ Finalizado: SINCRONIZAR BASE DE DATOS REMOTA"

### === SINCRONIZAR HEROKU === ###
echo "🟢 Iniciando: SINCRONIZAR HEROKU"

if [ "$OMIT_HEROKU" = false ]; then
    cd "$HEROKU_ROOT"
    git add .
    git commit -m "Auto sync"
    git push heroku main
fi

echo "✅ Finalizado: SINCRONIZAR HEROKU"

### === REINICIAR GUNICORN === ###
echo "🟢 Iniciando: REINICIAR GUNICORN"

if [ "$OMIT_GUNICORN" = false ]; then
    sudo systemctl restart gunicorn
fi

echo "✅ Finalizado: REINICIAR GUNICORN"
