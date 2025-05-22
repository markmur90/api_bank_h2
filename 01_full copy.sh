#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# === FUNCIONES UTILITARIAS ===
LOG_FILE_SCRIPT="$PROJECT_DIR/tmp/deploy_$(date +%Y%m%d_%H%M%S).log"

log_info()    { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE_SCRIPT"; }
log_ok()      { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE_SCRIPT"; }
log_error()   { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE_SCRIPT"; }

check_status() {
    local status=$?
    if [ $status -ne 0 ]; then
        log_error "Fallo al ejecutar: $1"
        exit $status
    else
        log_ok "Éxito: $1"
    fi
}

diagnostico_entorno() {
    echo -e "\n\033[1;35m🔍 Diagnóstico del Sistema:\033[0m"
    echo "🧠 Memoria RAM:"
    free -h
    echo ""
    echo "💾 Espacio en disco:"
    df -h /
    echo ""
    echo "🧮 Uso de CPU:"
    top -bn1 | grep "Cpu(s)"
    echo ""
    echo "🌐 Conectividad:"
    ip a | grep inet
    echo ""
    echo "🔥 Procesos activos de Python, PostgreSQL y Gunicorn:"
    ps aux | grep -E 'python|postgres|gunicorn' | grep -v grep
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m\n"
}

# === LLAMAR AL DIAGNÓSTICO TEMPRANO ===
diagnostico_entorno

PROMPT_MODE=true
OMIT_SYNC_REMOTE_DB=false
OMIT_HEROKU=false
OMIT_GUNICORN=false
OMIT_CLEAN=false
OMIT_JSON_LOCAL=false
# OMIT_JSON_WEB=false
OMIT_SYNC_LOCAL=false
OMIT_ZIP_SQL=false
OMIT_MAC=false
OMIT_LOAD_LOCAL=false
OMIT_LOAD_WEB=false
OMIT_USER=false

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2_H"
BACKUP_DIR="$HOME/Documentos/GitHub/backup"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
HEROKU_ROOT2="$HOME/Documentos/GitHub/api_bank"
VENV_PATH="$HOME/Documentos/Entorno/venvAPI"
INTERFAZ="wlan0"

DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"



# === OPCIONES DISPONIBLES PARA ./01_full.sh ===
# -a  --all                Ejecuta todo sin confirmaciones interactivas
# -s  --step               Modo paso a paso (requiere confirmar cada paso)
# -B  --omit-bdd           Omite sincronización de la base de datos remota
# -H  --omit-heroku        Omite sincronización o deploy en Heroku
# -G  --omit-gunicorn      Omite reinicio del servidor Gunicorn
# -L  --omit-local         Omite generación de respaldos JSON locales
# -W  --omit-web           Omite generación de respaldos JSON web
# -S  --omit-sync          Omite sincronización de respaldos locales
# -Z  --omit-zip           Omite creación de archivo ZIP del respaldo SQL
# -U  --omit-create-user   Omite creación del usuario
# -l  --omit-load-local    Omite carga de respaldo local
# -w  --omit-load-web      Omite carga de respaldo web
# -M  --omit-mac           Omite comandos específicos para macOS
# -C  --omit-clean         Omite limpieza de archivos temporales

# === COMBINACIONES RECOMENDADAS ===
# ./01_full.sh -a                           # Todo automático
# ./01_full.sh -a -W -L -Z                  # Todo excepto respaldos
# ./01_full.sh -a -U -w                     # Sin creación de usuario ni carga web
# ./01_full.sh -s -B -H -G                  # Modo paso a paso sin despliegue remoto
# ./01_full.sh -a -H -C -G -W -Z -U         # Desarrollo local, sin deploy ni limpieza
# ./01_full.sh -a -H -G -U -W               # Solo sincronizar y cargar backups locales
# ./01_full.sh -a -W -L                     # Solo compresión y carga sin generar respaldos
# ./01_full.sh -a -H -C -G -W -Z -U         # Desarrollo local sin limpieza ni despliegue
# ./01_full.sh -a -L -l -W -U               # Solo pruebas sin tocar backups ni usuarios:



mkdir -p "$BACKUP_DIR"

function usage() {
    echo "Uso: $0 [opciones]"
    echo
    echo "Opciones:"
    echo "  -a, --all                   Ejecuta todos los pasos automáticamente"
    echo "  -s, --step                  Ejecuta paso a paso con confirmación"
    echo "  -B, --omit-bdd              Omitir sincronización de la base de datos remota"
    echo "  -H, --omit-heroku           Omitir despliegue en Heroku"
    echo "  -G, --omit-gunicorn         Omitir arranque del servidor Gunicorn"
    echo "  -L, --omit-local            Omitir crear de JSON local"
    # echo "  -W, --omit-web              Omitir crear de JSON web"
    echo "  -S, --omit-sync             Omitir sincronización de archivos locales"
    echo "  -Z, --omit-zip              Omitir compresión de archivos"
    echo "  -M, --omit-mac              Omitir ajustes específicos para macOS"
    echo "  -U, --omit-create-user      Omitir crear usuario"
    echo "  -l, --omit-load-local       Omitir subir JSON local"
    echo "  -w, --omit-web              Omitir abrir web Heroku"
    echo "  -C, --omit-clean            Omitir limpieza de archivos temporales"
    echo "  -h, --help                  Mostrar esta ayuda y salir"
    echo
}
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all) PROMPT_MODE=false; shift ;;
        -s|--step) PROMPT_MODE=true; shift ;;
        -B|--omit-bdd) OMIT_SYNC_REMOTE_DB=true; shift ;;
        -H|--omit-heroku) OMIT_HEROKU=true; shift ;;
        -G|--omit-gunicorn) OMIT_GUNICORN=true; shift ;;
        -L|--omit-local) OMIT_JSON_LOCAL=true; shift ;;
        # -W|--omit-web) OMIT_JSON_WEB=true; shift ;;
        -S|--omit-sync) OMIT_SYNC_LOCAL=true; shift ;;
        -Z|--omit-zip) OMIT_ZIP_SQL=true; shift ;;
        -U|--omit-create-user) OMIT_USER=true; shift ;;
        -l|--omit-load-local) OMIT_LOAD_LOCAL=true; shift ;;
        -w|--omit-web) OMIT_LOAD_WEB=true; shift ;;
        -M|--omit-mac) OMIT_MAC=true; shift ;;
        -C|--omit-clean) OMIT_CLEAN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Opción desconocida: $1"; usage; exit 1 ;;
    esac
done


confirmar() {
    [[ "$PROMPT_MODE" == false ]] && return 0
    echo
    printf "\033[1;34m🔷 ¿Confirmas: %s? (s/n):\033[0m " "$1"
    read -r resp
    [[ "$resp" =~ ^[sS]$ || -z "$resp" ]]
    echo ""
}

clear


# echo -e "\033[7;33m----------------------------------------------PUERTOS----------------------------------------------\033[0m"
# if confirmar "Detener puertos abiertos"; then
#     PUERTOS_OCUPADOS=0
#     for PUERTO in 2222 8000 5000 8001 35729; do
#         if lsof -i tcp:"$PUERTO" &>/dev/null; then
#             PUERTOS_OCUPADOS=$((PUERTOS_OCUPADOS + 1))
#             if confirmar "Cerrar procesos en puerto $PUERTO"; then
#                 sudo fuser -k "${PUERTO}"/tcp || true
#                 echo -e "\033[7;30m✅ Puerto $PUERTO liberado.\033[0m"
#                 echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#                 echo ""
#             fi
#         fi
#     done
#     if [ "$PUERTOS_OCUPADOS" -eq 0 ]; then
#         echo -e "\033[7;31m🚫 No se encontraron procesos en los puertos definidos.\033[0m"
#         echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#         echo ""
#     fi
# fi
# echo ""
# echo ""
# echo ""
# sleep 3
# clear


# echo -e "\033[7;33m--------------------------------------------CONTENEDORES-------------------------------------------\033[0m"
# if confirmar "Detener contenedores Docker"; then
#     PIDS=$(docker ps -q)
#     if [ -n "$PIDS" ]; then
#         docker stop $PIDS
#         echo -e "\033[7;30m🐳 Contenedores detenidos.\033[0m"
#         echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#         echo ""
#     else
#         echo -e "\033[7;30m🐳 No hay contenedores.\033[0m"
#         echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#         echo ""
#     fi
# fi
# echo ""
# echo ""
# echo ""
# sleep 3
# clear


echo -e "\033[7;33m----------------------------------------------SISTEMA----------------------------------------------\033[0m"
if confirmar "Actualizar sistema"; then
    sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean
    echo -e "\033[7;30m🔄 Sistema actualizado.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear


echo -e "\033[7;33m------------------------------------------RESPALDOS LOCAL------------------------------------------\033[0m"
if [[ "$OMIT_JSON_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear bdd_local"); then
    echo -e "\033[7;30m🚀 Creando respaldo de datos de local...\033[0m"
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    python3 manage.py dumpdata --indent 2 > bdd_local.json
    echo -e "\033[7;30m✅ ¡Respaldo JSON Local creado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear


echo -e "\033[7;33m----------------------------------------------POSTGRES---------------------------------------------\033[0m"
if confirmar "Configurar venv y PostgreSQL"; then
    python3 -m venv "$VENV_PATH"
    source "$VENV_PATH/bin/activate"
    pip install --upgrade pip
    echo "📦 Instalando dependencias..."
    echo ""
    pip install -r "$PROJECT_ROOT/requirements.txt"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    echo -e "\033[7;30m🐍 Entorno y PostgreSQL listos.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear


# echo -e "\033[7;33m------------------------------------------------UFW------------------------------------------------\033[0m"
# if confirmar "Configurar UFW"; then
#     sudo ufw --force reset
#     sudo ufw default deny incoming
#     sudo ufw default allow outgoing
#     sudo ufw allow 22/tcp
#     sudo ufw allow 443/tcp
#     sudo ufw allow 2222/tcp
#     sudo ufw allow 8000/tcp
#     sudo ufw allow 8443/tcp
#     sudo ufw allow 5000/tcp
#     sudo ufw allow 35729/tcp
#     sudo ufw allow from 127.0.0.1 to any port 8001 proto tcp comment "Gunicorn local backend"
#     sudo ufw deny 22/tcp comment "Bloquear SSH real en 22"
#     sudo ufw enable
#     echo -e "\033[7;30m🔐 Reglas de UFW aplicadas con éxito.\033[0m"
#     echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#     echo ""
# fi
# echo ""
# echo ""
# echo ""
# sleep 3
# clear


echo -e "\033[7;33m----------------------------------------------RESETEO----------------------------------------------\033[0m"
if confirmar "Resetear base de datos y crear usuario en PostgreSQL"; then
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    sudo -u postgres psql <<-EOF
DO \$\$
BEGIN
    -- Verificar si el usuario ya existe
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;

-- Asignar permisos al usuario
ALTER USER ${DB_USER} WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
EOF
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1
if [ $? -eq 0 ]; then
    echo "La base de datos ${DB_NAME} existe. Eliminándola..."
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';"
    sudo -u postgres psql -c "DROP DATABASE ${DB_NAME};"
fi
sudo -u postgres psql <<-EOF
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CREATE ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF
    echo -e "\033[7;30mBase de datos y usuario recreados.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear


echo -e "\033[7;33m--------------------------------------------MIGRACIONES--------------------------------------------\033[0m"
if confirmar "Ejecutar migraciones"; then
    cd "$PROJECT_ROOT"
    source "$VENV_PATH/bin/activate"
    echo "🧹 Eliminando cachés de Python y migraciones anteriores..."
    find . -path "*/__pycache__" -type d -exec rm -rf {} +
    find . -name "*.pyc" -delete
    find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
    find . -path "*/migrations/*.pyc" -delete
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    echo "🔄 Generando migraciones de Django..."
    python manage.py makemigrations
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""    
    echo "⏳ Aplicando migraciones de la base de datos..."
    python manage.py migrate
    echo "⏳ Migraciones a la base de datos completa."
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear


echo -e "\033[7;33m----------------------------------------------USUARIO----------------------------------------------\033[0m"
if [[ "$OMIT_USER" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear Super Usuario"); then
    echo -e "\033[7;30m🚀 Creando usuario...\033[0m"
    python3 manage.py createsuperuser
    echo -e "\033[7;30m✅ ¡Usuario creado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear


echo -e "\033[7;33m--------------------------------------------CARGAR LOCAL-------------------------------------------\033[0m"
if [[ "$OMIT_LOAD_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir bdd_local"); then
    echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m"
    python3 manage.py loaddata bdd_local.json
    echo -e "\033[7;30m✅ ¡Subido JSON Local!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear






# echo -e "\033[7;33m----------------------------------------------PEM JWKS---------------------------------------------\033[0m"
# if confirmar "Generar o cambiar PEM JWKS"; then
#     echo -e "\033[7;30m🚀 Generando PEM...\033[0m"
#     python3 manage.py genkey
#     echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#     echo ""
# fi
# echo ""
# echo ""
# echo ""
# sleep 3
# clear


echo -e "\033[7;33m----------------------------------------SINCRONIZACION LOCAL----------------------------------------\033[0m"

EXCLUDES=(
    "--exclude=.gitattributes"
    "--exclude=.git/"
    "--exclude=01_full.sh"
    "--exclude=02_full.sh"
    "--exclude=api_bank_heroku.txt"
    "--exclude=auto_commit_sync.sh"
    "--exclude=bdd_local.json"
    "--exclude=bdd_web.json"
    "--exclude=colores.sh"
    "--exclude=cert.pem"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    "--exclude=*.zip"
    "--exclude=gunicorn.log"
    "--exclude=honeypot.log"
    "--exclude=honeypot.py"
    "--exclude=honeypot_logs.csv"
    "--exclude=iconos.sh"
    "--exclude=livereload.log"
    "--exclude=nohup.out"
    "--exclude=privkey.pem"
    "--exclude=*local.py"
    "--exclude=temp/"
)
actualizar_django_env() {
    local destino="$1"
    echo "🌍 Actualizando DJANGO_ENV en base1.py de: $destino"
    python3 <<EOF
import os
settings_path = os.path.join("$destino", "config", "settings", "base1.py")
if os.path.exists(settings_path):
    with open(settings_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    updated = False
    new_lines = []
    for line in lines:
        if "DJANGO_ENV = os.getenv(" in line and "'local'" in line:
            new_lines.append(line.replace("'local'", "'production'"))
            updated = True
        else:
            new_lines.append(line)
    if updated:
        with open(settings_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print("✅ DJANGO_ENV actualizado a 'production' en base1.py.")
    else:
        print("⚠️ No se encontró 'DJANGO_ENV' con valor 'local' para actualizar.")
else:
    print("⚠️ No se encontró base1.py para actualizar DJANGO_ENV.")
EOF
}

if [[ "$OMIT_SYNC_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Sincronizas archivos locales"); then
    for destino in "$HEROKU_ROOT" "$HEROKU_ROOT2"; do
        echo -e "\033[7;30m🔄 Sincronizando archivos al destino: $destino\033[0m"
        rsync -av "${EXCLUDES[@]}" "$PROJECT_ROOT/" "$destino/"
        echo -e "\033[7;30m📂 Cambios enviados a $destino.\033[0m"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
        echo ""
        cd "$destino"
        actualizar_django_env "$destino"
        cd "$PROJECT_ROOT"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
        echo ""
    done
fi

echo ""
echo ""
echo ""
sleep 3
clear


echo -e "\033[7;33m-------------------------------------------SUBIR A HEROKU------------------------------------------\033[0m"
if [[ "$OMIT_HEROKU" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir el proyecto a la web"); then
    echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
    cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    echo -e "\033[7;30mHaciendo git add...\033[0m"
    git add --all
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    echo -e "\033[7;30mPor favor, ingrese el comentario del commit:\033[0m"
    read -p "✏️  Comentario: " COMENTARIO_COMMIT
    if [[ -z "$COMENTARIO_COMMIT" ]]; then
        echo -e "\033[7;31m❌ No se puede continuar sin un comentario de commit.\033[0m"
        exit 1
    fi
    echo -e "\033[7;30mHaciendo commit con el mensaje: \"$COMENTARIO_COMMIT\"...\033[0m"
    git commit -m "$COMENTARIO_COMMIT"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    echo -e "\033[7;30mHaciendo push a GitHub...\033[0m"
    git push origin api-bank || { echo -e "\033[7;30m❌ Error al subir a GitHub\033[0m"; exit 0; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    sleep 20
    export HEROKU_API_KEY="HRKU-6803f1ea-fd1f-4210-a5cd-95ca7902ccf6"
    echo "$HEROKU_API_KEY" | heroku auth:token
    echo -e "\033[7;30mHaciendo push a Heroku...\033[0m"
    git push heroku api-bank:main || { echo -e "\033[7;30m❌ Error en deploy\033[0m"; exit 0; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    sleep 20
    cd "$PROJECT_ROOT"
    echo -e "\033[7;30m✅ ¡Deploy completado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear








echo -e "\033[7;33m---------------------------------------SINCRONIZACION BDD WEB--------------------------------------\033[0m"
if [[ "$OMIT_SYNC_REMOTE_DB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir las bases de datos a la web"); then

    echo -e "\033[7;30mSubiendo las bases de datos a la web...\033[0m"
    LOCAL_DB_NAME="mydatabase"
    LOCAL_DB_USER="markmur88"
    LOCAL_DB_HOST="localhost"
    REMOTE_DB_URL="postgres://u5n97bps7si3fm:pb87bf621ec80bf56093481d256ae6678f268dc7170379e3f74538c315bd549e0@c7lolh640htr57.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/dd3ico8cqsq6ra"

    export PGPASSFILE="$HOME/.pgpass"
    export PGUSER="$LOCAL_DB_USER"
    export PGHOST="$LOCAL_DB_HOST"

    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="$HOME/Documentos/GitHub/backup/"
    BACKUP_FILE="${BACKUP_DIR}backup_${DATE}.sql"

    if ! command -v pv > /dev/null 2>&1; then
        echo "⚠️ La herramienta 'pv' no está instalada. Instálala con: sudo apt install pv"
        exit 1
    fi
    echo -e "\033[7;30m🧹 Reseteando base de datos remota...\033[0m"
    psql "$REMOTE_DB_URL" -q -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" || { echo "❌ Error al resetear la DB remota. Abortando."; exit 1; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    echo -e "\033[7;30m📦 Generando backup local...\033[0m"
    pg_dump --no-owner --no-acl -U "$LOCAL_DB_USER" -h "$LOCAL_DB_HOST" -d "$LOCAL_DB_NAME" > "$BACKUP_FILE" || { echo "❌ Error haciendo el backup local. Abortando."; exit 1; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    echo -e "\033[7;30m🌐 Importando backup en la base de datos remota...\033[0m"
    pv "$BACKUP_FILE" | psql "$REMOTE_DB_URL" -q > /dev/null || { echo "❌ Error al importar el backup en la base de datos remota."; exit 1; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    echo -e "\033[7;30m✅ Sincronización completada con éxito: $BACKUP_FILE"
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
clear





echo -e "\033[7;33m--------------------------------------------------ZIP----------------------------------------------\033[0m"
if [[ "$OMIT_ZIP_SQL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear zip y sql"); then
    SOURCE="$PROJECT_ROOT/"
    DEST="$HOME/Documentos/GitHub/api_bank_heroku/"
    BACKUP_DIR="$HOME/Documentos/GitHub/backup/"

    # Obtener la fecha actual (solo día)
    TODAY=$(date +%Y%m%d)

    # Contar cuántos backups hay hoy y sumar 1 para el siguiente consecutivo
    COUNT=$(ls "$BACKUP_DIR" | grep "^${TODAY}__.*_backup_api_bank_h2_H_[0-9]*\.zip$" | wc -l)
    SUFFIX=$((COUNT + 1))

    # Timestamp con hora
    TIMESTAMP=$(date +%Y%m%d__%H-%M-%S)

    # Nombre final del archivo
    BACKUP_ZIP="${BACKUP_DIR}${TIMESTAMP}_backup_api_bank_h2_H_${SUFFIX}.zip"

    sudo mkdir -p "$DEST" "$BACKUP_DIR"
    echo "📦 Creando archivo ZIP de respaldo..."
    (
        cd "$(dirname "$SOURCE")"
        sudo zip -r "$BACKUP_ZIP" "$(basename "$SOURCE")" --exclude=".git/" --exclude="*.zip" --exclude="__pycache__/" --exclude="*.sqlite3" --exclude="*.db" --exclude="*.pyc" --exclude="*.pyo"
    )
    echo ""
    # echo "🔄 Sincronizando archivos al destino..."
    # rsync -av --exclude=".gitattributes" --exclude="auto_commit_sync.sh" --exclude="manage.py" --exclude="*local.py" --exclude=".git/" --exclude="gunicorn.log" --exclude="honeypot_logs.csv" --exclude="token.md" --exclude="url_help.md" --exclude="honeypot.py" --exclude="URL_TOKEN.md" --exclude="01_full.sh" --exclude="05Gunicorn.sh" --exclude="*.zip" --exclude="*.db" --exclude="*.sqlite3" --exclude="temp/" "$SOURCE" "$DEST"
    # echo ""
    echo -e "\033[7;30m✅ Respaldo ZIP creado en: $BACKUP_ZIP\033[0m"
    # cd "$BACKUP_DIR" || exit 1
    # TODAY=$(date +%Y%m%d)
    # today_files=( $(ls -1t "${TODAY}__"*.zip 2>/dev/null) )
    # for f in "${today_files[@]:10}"; do sudo rm -- "$f"; done
    # dates=( $(ls -1 *.zip | grep -E '^[0-9]{8}__' | cut -c1-8 | grep -v "^$TODAY" | sort -u) )
    # for d in "${dates[@]}"; do
    #     files=( $(ls -1t "${d}__"*.zip) )
    #     for f in "${files[@]:1}"; do sudo rm -- "$f"; done
    # done
    echo ""
    echo "🧹 Archivos ZIP antiguos eliminados."
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 1
clear




echo -e "\033[7;33m-----------------------------------------BORRANDO ZIP Y SQL----------------------------------------\033[0m"
if [[ "$OMIT_CLEAN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Limpiar respaldos antiguos"); then
    echo -e "\033[7;30mLimpiando respaldos antiguos...\033[0m"
    echo ""
    cd "$BACKUP_DIR"
    mapfile -t files < <(ls -1tr *.zip *.sql 2>/dev/null)
    declare -A first last all keep
    for f in "${files[@]}"; do
        d=${f:10:8}
        all["$d"]+="$f;"
        [[ -z "${first[$d]:-}" ]] && first[$d]=$f
        last[$d]=$f
    done
    today=$(date +%Y%m%d)
    for d in "${!first[@]}"; do keep["${first[$d]}"]=1; done
    for d in "${!last[@]}";  do keep["${last[$d]}"]=1;  done
    today_files=(); for f in "${files[@]}"; do [[ "${f:10:8}" == "$today" ]] && today_files+=("$f"); done
    n=${#today_files[@]}; s=$(( n>10 ? n-10 : 0 ))
    for ((i=s;i<n;i++)); do keep["${today_files[i]}"]=1; done
    for f in "${files[@]}"; do
        if [[ -z "${keep[$f]:-}" ]]; then 
            rm -f "$f" && echo -e "\033[7;30m🗑️ Eliminado $f.\033[0m"
            echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
            echo ""
        fi
    done
    cd - >/dev/null
fi
echo ""
echo ""
echo ""
sleep 3
clear



# echo -e "\033[7;33m---------------------------------------------CAMBIO MAC--------------------------------------------\033[0m"
# if [[ "$OMIT_MAC" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Cambiar MAC de la interfaz $INTERFAZ"); then
#     echo -e "\033[7;30mCambiando MAC de la interfaz $INTERFAZ\033[0m"
#     sudo ip link set "$INTERFAZ" down
#     MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
#     MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
#     sudo ip link set "$INTERFAZ" up
#     echo -e "\033[7;30m🔍 MAC anterior: $MAC_ANTERIOR\033[0m"
#     echo -e "\033[7;30m🎉 MAC asignada: $MAC_NUEVA\033[0m"
#     echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#     echo ""
# fi
# echo ""
# echo ""
# echo ""
# sleep 3
# clear


#!/bin/bash

echo -e "\033[7;33m----------------------------------------------GUNICORN---------------------------------------------\033[0m"

# === CONFIGURACIÓN ===
PUERTOS=(8001 5000 35729)
URL_LOCAL="http://localhost:5000"
URL_GUNICORN="http://0.0.0.0:8000"
URL_HEROKU="https://apibank2-d42d7ed0d036.herokuapp.com/"
LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

# === FUNCIONES ===
liberar_puertos() {
    for port in "${PUERTOS[@]}"; do
        if lsof -i :$port > /dev/null; then
            echo -e "\033[1;34m🔌 Liberando puerto $port...\033[0m"
            kill $(lsof -t -i :$port) 2>/dev/null || true
        fi
    done
}

limpiar_y_salir() {
    echo -e "\n\033[1;33m🧹 Deteniendo todos los servicios...\033[0m"
    pids=$(jobs -p)
    [ -n "$pids" ] && kill $pids 2>/dev/null
    [ -n "$FIREFOX_PID" ] && kill "$FIREFOX_PID" 2>/dev/null || true
    liberar_puertos
    echo -e "\033[1;32m✅ Todos los servicios detenidos.\033[0m"
    echo -e "$LOGO_SEP\n"
    exit 0
}

iniciar_entorno() {
    cd "$PROJECT_ROOT"
    source "$VENV_PATH/bin/activate"
    python manage.py collectstatic --noinput
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
}

# === INICIO GUNICORN + HONEYPOT ===
if [[ "$OMIT_GUNICORN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Iniciar Gunicorn, honeypot y livereload"); then
    echo -e "\033[7;30m🚀 Iniciando Gunicorn, honeypot y livereload...\033[0m"
    trap limpiar_y_salir SIGINT
    liberar_puertos
    iniciar_entorno

    nohup gunicorn config.wsgi:application --workers 3 --bind 0.0.0.0:8001 --keep-alive 2 > gunicorn.log 2>&1 < /dev/null &
    nohup python honeypot.py > honeypot.log 2>&1 < /dev/null &
    nohup livereload --host 0.0.0.0 --port 35729 static/ -t templates/ > livereload.log 2>&1 < /dev/null &
    
    sleep 3
    firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN"

    echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
    echo -e "$LOGO_SEP\n"
    while true; do sleep 3; done
fi
echo -e "\n\n\n"
sleep 3
clear




# === ABRIR WEB HEROKU ===
echo -e "\033[7;33m---------------------------------------------CARGAR WEB--------------------------------------------\033[0m"

if [[ "$OMIT_LOAD_WEB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Abrir web Heroku"); then
    echo -e "\033[7;30m🌐 Abriendo web de Heroku...\033[0m"
    trap limpiar_y_salir SIGINT
    liberar_puertos
    iniciar_entorno

    firefox --new-window "$URL_HEROKU" &
    FIREFOX_PID=$!

    echo -e "\033[7;30m🚧 Web Heroku activa. Ctrl+C para cerrar.\033[0m"
    echo -e "$LOGO_SEP\n"
    while true; do sleep 3; done
fi

echo -e "\n\n\n"
sleep 3
clear





# === FIN: CORREGIDO EL BLOQUE PROBLEMÁTICO ===
URL="$URL_LOCAL"

notify-send "API_BANK_H2_H" "✅ Proyecto iniciado correctamente en:
$URL
$URL_HEROKU
🏁 ¡Todo completado con éxito!
✅ Sincronización completada con éxito: $BACKUP_FILE
📦 Commit con el mensaje: $COMENTARIO_COMMIT
✅ Respaldo ZIP creado en: $BACKUP_ZIP"

log_ok "🎉 Script finalizado sin errores."
log_info "🗂 Log disponible en: $LOG_FILE_SCRIPT"



