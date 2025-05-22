#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
HEROKU_ROOT2="$HOME/Documentos/GitHub/coretransapi"
VENV_PATH="$HOME/Documentos/Entorno/venvAPI"
INTERFAZ="wlan0"




PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
LOGS_DIR="$PROJECT_ROOT/logs"
LOG_FILE_SCRIPT="$LOGS_DIR/full_deploy_$(date +%Y%m%d_%H%M%S).log"

# === FUNCIONES UTILITARIAS ===
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

ejecutar() {
    log_info "➡️ Ejecutando: $*"
    "$@" >> "$LOG_FILE_SCRIPT" 2>&1
    check_status "$*"
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


# mkdir -p "$BACKUP_DIR"

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

# confirmar() {
#     [[ "$PROMPT_MODE" == false ]] && return 0
#     echo
#     printf "\033[1;34m🔷 ¿Confirmas: %s? (s/n, 15s para cancelar):\033[0m " "$1"
#     read -t 15 -r resp || resp="n"
#     [[ "$resp" =~ ^[sS]$ ]]
#     echo ""
# }

echo -e "\033[7;33m--------------------------------------------------ZIP----------------------------------------------\033[0m"

if [[ "$OMIT_ZIP_SQL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear zip y sql"); then
    echo -e "\033[7;30mCreando ZIP archivos al destino...\033[0m"

    bash /home/markmur88/Documentos/GitHub/api_bank_h2/scripts/15_zip_backup.sh
    
    # PROJECT_ROOT="/home/markmur88/Documentos/GitHub/api_bank_h2"
    # PROJECT_BASE_DIR="/home/markmur88/Documentos/GitHub"
    # BACKUP_DIR="$PROJECT_BASE_DIR/backup"

    # mkdir -p "$BACKUP_DIR"

    # FECHA=$(date +%Y%m%d)
    # CONTEO=$(ls "$BACKUP_DIR"/respaldo_"$FECHA"_*.zip 2>/dev/null | wc -l)
    # NUM=$(printf "%03d" $((CONTEO + 1)))
    # ZIP_PATH="$BACKUP_DIR/respaldo_${FECHA}_${NUM}.zip"

    # echo -e "\033[1;34m🔐 Asignando permisos de lectura a todos los archivos y ejecución a carpetas...\033[0m"
    # find "$PROJECT_ROOT" -type f -exec chmod u+r {} +
    # find "$PROJECT_ROOT" -type d -exec chmod u+rx {} +

    # echo -e "\033[1;34m📦 Creando respaldo ZIP completo sin excluir ningún archivo...\033[0m"
    # zip -r "$ZIP_PATH" "$PROJECT_ROOT" || echo -e "\033[0;31m❌ Error creando el ZIP en $ZIP_PATH\033[0m"

    # if [[ -f "$ZIP_PATH" ]]; then
    #     echo -e "\033[7;30m📦 ZIP creado: $ZIP_PATH.\033[0m"
    # else
    #     echo -e "\033[0;31m❌ ZIP no fue creado.\033[0m"
    # fi

    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi


echo ""
echo ""
echo ""
sleep 3



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
# sleep 3
# # clear



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
# sleep 3
# # clear



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
# clear



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
# clear



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
# clear



echo -e "\033[7;33m------------------------------------------------UFW------------------------------------------------\033[0m"
if confirmar "Configurar UFW"; then
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    # Reglas básicas
    sudo ufw allow 22/tcp      # SSH
    sudo ufw allow 80/tcp      # HTTP
    sudo ufw allow 443/tcp     # HTTPS
    sudo ufw allow 8000/tcp    # HTTPS
    sudo ufw allow 18080/tcp    # HTTPS
    sudo ufw allow 18081/tcp    # HTTPS
    sudo ufw allow 28080/tcp    # HTTPS
    sudo ufw allow 28081/tcp    # HTTPS
    sudo ufw allow 49222/tcp   # HTTPS NJALLA

    # Gunicorn y PostgreSQL solo local
    sudo ufw allow from 127.0.0.1 to any port 8000
    sudo ufw allow from 127.0.0.1 to any port 8011
    sudo ufw allow from 127.0.0.1 to any port 8001
    sudo ufw allow from 127.0.0.1 to any port 5432

    # Honeypot SSH
    sudo ufw allow 2222/tcp

    # Supervisor local
    sudo ufw allow from 127.0.0.1 to any port 9001

    # Tor
    sudo ufw allow from 127.0.0.1 to any port 9050
    sudo ufw allow from 127.0.0.1 to any port 9051

    # DNS y NTP salientes
    sudo ufw allow out 53
    sudo ufw allow out 123/udp

    # Heroku CLI saliente
    sudo ufw allow out to any port 443

    # Monero (XMR)
    sudo ufw allow 18080/tcp                                     # Nodo P2P abierto
    sudo ufw allow proto tcp from 127.0.0.1 to any port 18082    # Wallet RPC local
    sudo ufw allow proto tcp from 127.0.0.1 to any port 18089:18100  # Rango wallets

    # Livereload (local)
    sudo ufw allow from 127.0.0.1 to any port 35729

    # Ghost API (local)
    sudo ufw allow from 127.0.0.1 to any port 5000

    # Activar UFW
    sudo ufw --force enable
    echo -e "\033[7;30m🔐 Reglas de UFW aplicadas con éxito.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi


echo ""
echo ""
echo ""
sleep 3
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
# clear



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
    echo "⏳ Aplicando Collectstatic..."
    python manage.py collectstatic --noinput
    echo "⏳ Migraciones a la base de datos completa."
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
fi


echo ""
echo ""
echo ""
sleep 3
# clear



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
# clear



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
# clear



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
# # clear



echo -e "\033[7;33m----------------------------------------SINCRONIZACION COMPLETA----------------------------------------\033[0m"

EXCLUDES=(
    "--exclude=.git/"
    "--exclude=*.zip"
    "--exclude=temp/"
)  # Puedes vaciarlo por completo si quieres TODO

actualizar_django_env() {
    local destino="$1"
    local entorno_base
    entorno_base=$(basename "$destino")

    local nuevo_valor_env

    case "$entorno_base" in
        local)
            nuevo_valor_env="local"
            ;;
        heroku)
            nuevo_valor_env="heroku"
            ;;
        coretransapi)
            nuevo_valor_env="production"
            ;;
        *)
            echo "⚠️  No se reconoce el entorno '$entorno_base'. Se omite actualización de DJANGO_ENV."
            return
            ;;
    esac

    echo "🌍 Actualizando DJANGO_ENV en __init__.py de: $destino (valor: $nuevo_valor_env)"

    local temp_script="/tmp/update_django_env.py"

    cat > "$temp_script" <<EOF
import os
settings_path = os.path.join("$destino", "config", "settings", "__init__.py")

if os.path.exists(settings_path):
    with open(settings_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    updated = False
    new_lines = []
    for line in lines:
        if "DJANGO_ENV = os.getenv(" in line:
            if f'"$nuevo_valor_env"' not in line:
                new_lines.append(f'DJANGO_ENV = os.getenv("DJANGO_ENV", "$nuevo_valor_env")\\n')
                updated = True
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    if updated:
        with open(settings_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print("✅ DJANGO_ENV actualizado a '$nuevo_valor_env' en __init__.py.")
    else:
        print("🔍 DJANGO_ENV ya estaba configurado como '$nuevo_valor_env'. No se realizaron cambios.")
else:
    print("⚠️ No se encontró __init__.py para actualizar DJANGO_ENV.")
EOF

    python3 "$temp_script" || {
        echo "🔐 Intentando con privilegios elevados (sudo)..."
        sudo python3 "$temp_script"
    }

    rm -f "$temp_script"
}

if [[ "$OMIT_SYNC_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "¿Sincronizas archivos locales?"); then
    for destino in "$HEROKU_ROOT" "$HEROKU_ROOT2" "$PROJECT_ROOT"; do
        echo -e "\033[7;30m🔄 Sincronizando archivos al destino: $destino\033[0m"
        sudo rsync -av "${EXCLUDES[@]}" "$PROJECT_ROOT/" "$destino/"
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
# clear





echo -e "\033[7;33m-------------------------------------------SUBIR A HEROKU------------------------------------------\033[0m"
if [[ "$OMIT_HEROKU" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir el proyecto a la web"); then
    echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
    cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    # Configurar variable DJANGO_SETTINGS_MODULE
    echo -e "\033[7;36m🔧 Configurando DJANGO_SETTINGS_MODULE en Heroku...\033[0m"
    heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production
    CLAVE_SEGURA=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(64)))")
    heroku config:set DJANGO_SECRET_KEY="$CLAVE_SEGURA"
    heroku config:set DJANGO_DEBUG=False
    heroku config:set DJANGO_ALLOWED_HOSTS=*.herokuapp.com
    # heroku config:set DB_CLIENT_ID=tu-client-id-herokuPtf8454Jd55
    # heroku config:set DB_CLIENT_SECRET=tu-client-secret-heroku
    heroku config:set DB_TOKEN_URL=https://simulator-api.db.com:443/gw/dbapi/token
    heroku config:set DB_AUTH_URL=https://simulator-api.db.com:443/gw/dbapi/authorize
    heroku config:set DB_API_URL=https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer
    heroku config:set DB_SCOPE=sepa_credit_transfers
    heroku config:set API_ORIGIN=https://simulator-api.db.com
    heroku config:set TIMEOUT_REQUEST=3600
    heroku config:set DISABLE_COLLECTSTATIC=1
    heroku config:set PRIVATE_KEY_B64="$(cat ghost.key.b64)"

    echo -e "\033[7;36m🔐 Verificando y generando clave privada JWT...\033[0m"
    # Crear carpeta keys/ si no existe
    mkdir -p keys
    # Ruta esperada del archivo
    PEM_PATH="/home/markmur88/Documentos/GitHub/api_bank_h2/schemas/keys/ecdsa_private_key.pem"
    # Verificar existencia de la clave privada
    if [[ ! -f "$PEM_PATH" ]]; then
        echo -e "\033[7;33m⚠️  Clave privada no encontrada. Generando clave ECDSA P-256...\033[0m"
        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$PEM_PATH"
        echo -e "\033[7;32m✅ Clave privada generada en $PEM_PATH\033[0m"
    else
        echo -e "\033[7;32m🔎 Clave privada ya existente.\033[0m"
    fi
    # Validar contenido del archivo
    if ! grep -q "BEGIN PRIVATE KEY" "$PEM_PATH"; then
        echo -e "\033[7;31m❌ Error: El archivo $PEM_PATH no contiene una clave privada válida.\033[0m"
        exit 1
    fi
    # Configurar PRIVATE_KEY_PATH si aún no está en Heroku
    if [[ -z "$(heroku config:get PRIVATE_KEY_PATH)" ]]; then
        echo -e "\033[7;36m🔧 Configurando PRIVATE_KEY_PATH en Heroku...\033[0m"
        heroku config:set PRIVATE_KEY_PATH="$PEM_PATH"
    else
        echo -e "\033[7;32m✅ PRIVATE_KEY_PATH ya está configurado en Heroku.\033[0m"
    fi
    # Configurar PRIVATE_KEY_KID si aún no está
    if [[ -z "$(heroku config:get PRIVATE_KEY_KID)" ]]; then
        echo -e "\033[7;36m🔑 Generando PRIVATE_KEY_KID aleatorio...\033[0m"
        PRIVATE_KEY_KID=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(32)))")
        heroku config:set PRIVATE_KEY_KID="$PRIVATE_KEY_KID"
        echo -e "\033[7;32m✅ PRIVATE_KEY_KID generado y configurado correctamente\033[0m"
    else
        echo -e "\033[7;32m✅ PRIVATE_KEY_KID ya está configurado en Heroku.\033[0m"
    fi
    heroku config:set OAUTH2_REDIRECT_URI=https://apibank2-d42d7ed0d036.herokuapp.com/oauth2/callback/
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
# clear







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
# clear



echo -e "\033[7;33m---------------------------------------------CAMBIO MAC--------------------------------------------\033[0m"
if [[ "$OMIT_MAC" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Cambiar MAC de la interfaz $INTERFAZ"); then
    echo -e "\033[7;30mCambiando MAC de la interfaz $INTERFAZ\033[0m"
    sudo ip link set "$INTERFAZ" down
    MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
    MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
    sudo ip link set "$INTERFAZ" up
    echo -e "\033[7;30m🔍 MAC anterior: $MAC_ANTERIOR\033[0m"
    echo -e "\033[7;30m🎉 MAC asignada: $MAC_NUEVA\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi


echo ""
echo ""
echo ""
sleep 3
# clear



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
    nohup "$VENV_PATH/bin/gunicorn" config.wsgi:application --workers 3 --bind 127.0.0.1:8001 --keep-alive 2 > "$LOGS_DIR/gunicorn_api.log" 2>&1 < /dev/null &
    nohup python honeypot.py > "$LOGS_DIR/honeypot.log" 2>&1 < /dev/null &
    nohup livereload --host 127.0.0.1 --port 35729 static/ -t templates/ > "$LOGS_DIR/livereload.log" 2>&1 < /dev/null &   
    sleep 3
    firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN"
    echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
    echo -e "$LOGO_SEP\n"
    while true; do sleep 3; done
fi


echo ""
echo ""
echo ""
sleep 3
# clear



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


echo ""
echo ""
echo ""
sleep 3
# clear



# === FIN: CORREGIDO EL BLOQUE PROBLEMÁTICO ===
URL="$URL_LOCAL"
notify-send "API_BANK_H2" "✅ Proyecto iniciado correctamente en:
$URL
$URL_HEROKU
🏁 ¡Todo completado con éxito!
✅ Sincronización completada con éxito: $BACKUP_FILE
📦 Commit con el mensaje: $COMENTARIO_COMMIT
log_info "🗂 Log disponible en: $LOG_FILE_SCRIPT"



base64 -w 0 /home/markmur88/Documentos/GitHub/api_bank_h2/servers/ssl/api_bank_h2/ghost.key > ghost.key.b64
