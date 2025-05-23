#!/usr/bin/env bash
set -euo pipefail

clear

echo "🔐 Solicitando acceso sudo..."
if sudo -v; then
    while true; do
        sudo -v
        sleep 60
    done &

    SUDO_KEEP_ALIVE_PID=$!
    trap 'kill $SUDO_KEEP_ALIVE_PID' EXIT
else
    echo "❌ No se pudo obtener acceso sudo. Abortando."
    exit 1
fi

COMENTARIO_COMMIT=""

# ╔════════════════════════════════════════════════════════════════════════════╗
# ║                    SCRIPT MAESTRO DE DESPLIEGUE - api_bank_h2           ║
# ║  Automatización total: setup, backups, deploy, limpieza y seguridad       ║
# ║  Soporte para 30 combinaciones de despliegue con alias `d_*`              ║
# ║  Ejecuta `deploy_menu` para selección interactiva con FZF                 ║
# ║  Ejecuta `d_help` para ver ejemplos combinados y sus parámetros           ║
# ║  Autor: markmur88                                                         ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# === CARGA DEL ENTORNO (.env) ===
ENV_FILE=".env"
if [[ -f "$ENV_FILE" ]]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo "🌍 Entorno cargado desde $ENV_FILE"
else
    echo "❌ Archivo .env no encontrado. Abortando..."
    exit 1
fi

# === VARIABLES DE PROYECTO ===
PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
HEROKU_ROOT2="$HOME/Documentos/GitHub/coretransapi"
VENV_PATH="$HOME/Documentos/Entorno/venvAPI"
INTERFAZ="wlan0"
LOGS_DIR="$PROJECT_ROOT/logs"
LOG_FILE_SCRIPT=${LOGFILE:-"$LOGS_DIR/full_deploy.log"}
STARTUP_LOG=${STARTUP_LOG:-"$LOGS_DIR/startup.log"}


# === CREDENCIALES BASE DE DATOS ===
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"

# === FLAGS DE CONTROL DE BLOQUES ===
PROMPT_MODE=true
OMIT_SYNC_REMOTE_DB=false
OMIT_HEROKU=false
OMIT_GUNICORN=false
OMIT_CLEAN=false
OMIT_JSON_LOCAL=false
OMIT_SYNC_LOCAL=false
OMIT_DOKER=false
OMIT_SYS=false
OMIT_ZIP_SQL=false
OMIT_MAC=false
OMIT_PEM=false
OMIT_PORTS=false
OMIT_MIG=false
OMIT_PGSQL=false
OMIT_RUN_LOCAL=false
OMIT_RUN_WEB=false
OMIT_UFW=false
OMIT_USER=false
OMIT_DEPLOY_VPS=false
OMIT_VERIF_TRANSF=false
DEBUG_MODE=false



# === FORMATO DE COLORES ===
RESET='\033[0m'
AZUL='\033[1;34m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
AMARILLO='\033[1;33m'

log_info()    { echo -e "${AZUL}[INFO] $1${RESET}" | tee -a "$LOG_FILE_SCRIPT"; }
log_ok()      { echo -e "${VERDE}[OK]   $1${RESET}" | tee -a "$LOG_FILE_SCRIPT"; }
log_error()   { echo -e "${ROJO}[ERR]  $1${RESET}" | tee -a "$LOG_FILE_SCRIPT"; }

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

usage() {
    echo -e ""
    echo -e "\033[7;34m                                ➤ SCRIPT MAESTRO DE DESPLIEGUE: api_bank_h2\033[0m"
    echo -e "\033[1;37mUso:\033[0m ./01_full.sh [opciones]"
    echo -e ""

    echo -e "\033[1;36m OPCIONES GENERALES\033[0m"
    echo -e "  \033[1;33m-a\033[0m, \033[1;33m--all\033[0m                Ejecuta todo automáticamente sin confirmaciones"
    echo -e "  \033[1;33m-s\033[0m, \033[1;33m--step\033[0m               Modo paso a paso con confirmación por bloque"
    echo -e "  \033[1;33m-d\033[0m, \033[1;33m--debug\033[0m              Muestra las variables de entorno antes de ejecutar"
    echo -e ""

    echo -e "\033[1;36m BLOQUES OMITIBLES INDIVIDUALMENTE\033[0m"
    echo -e "  \033[1;33m-B\033[0m, \033[1;33m--omit-bdd\033[0m           Omitir sincronización con la base de datos remota"
    echo -e "  \033[1;33m-H\033[0m, \033[1;33m--omit-heroku\033[0m        Omitir deploy y push a Heroku"
    echo -e "  \033[1;33m-G\033[0m, \033[1;33m--omit-gunicorn\033[0m      Omitir arranque de Gunicorn y servicios locales"
    echo -e "  \033[1;33m-C\033[0m, \033[1;33m--omit-clean\033[0m         Omitir limpieza de respaldos antiguos"
    echo -e "  \033[1;33m-D\033[0m, \033[1;33m--omit-docker\033[0m        Omitir detener containers Docker"
    echo -e "  \033[1;33m-P\033[0m, \033[1;33m--omit-ports\033[0m         Omitir detener puertos"
    echo -e "  \033[1;33m-Y\033[0m, \033[1;33m--omit-sys\033[0m           Omitir actualizar sistema"
    echo -e "  \033[1;33m-Z\033[0m, \033[1;33m--omit-zip\033[0m           Omitir creación de ZIP y SQL"
    echo -e ""

    echo -e "\033[1;36m RESPALDOS Y CARGAS DE DATOS\033[0m"
    echo -e "  \033[1;33m-L\033[0m, \033[1;33m--omit-local\033[0m         Omitir creación de JSON de respaldo local"
    echo -e "  \033[1;33m-I\033[0m, \033[1;33m--omit-migra\033[0m         Omitir migraciones"
    echo -e "  \033[1;33m-Q\033[0m, \033[1;33m--omit-pgsql\033[0m         Omitir reseteo postgres"
    echo -e "  \033[1;33m-S\033[0m, \033[1;33m--omit-sync\033[0m          Omitir sincronización entre carpetas"
    echo -e "  \033[1;33m-l\033[0m, \033[1;33m--omit-load-local\033[0m    Omitir carga de JSON local al sistema"
    echo -e "  \033[1;33m-w\033[0m, \033[1;33m--omit-web\033[0m           Omitir apertura del navegador con el entorno web"
    echo -e ""

    echo -e "\033[1;36m USUARIO Y VERIFICACIÓN\033[0m"
    echo -e "  \033[1;33m-U\033[0m, \033[1;33m--omit-create-user\033[0m   Omitir creación del superusuario de Django"
    echo -e "  \033[1;33m-V\033[0m, \033[1;33m--omit-verif-trans\033[0m   Omitir verificación de archivos de transferencia"
    echo -e ""

    echo -e "\033[1;36m OTROS\033[0m"
    echo -e "  \033[1;33m-M\033[0m, \033[1;33m--omit-mac\033[0m           Omitir cambio de dirección MAC aleatoria"
    echo -e "  \033[1;33m-x\033[0m, \033[1;33m--omit-ufw\033[0m           Omitir configuración del firewall (UFW)"
    echo -e "  \033[1;33m-p\033[0m, \033[1;33m--omit-pem\033[0m           Omitir generar archivos PEM"
    echo -e "  \033[1;33m-v\033[0m, \033[1;33m--omit-vps\033[0m           Omitir hacer deploy vps njalla"
    echo -e "  \033[1;33m-h\033[0m, \033[1;33m--help\033[0m               Mostrar esta ayuda y salir"
    echo -e ""

    echo -e "\033[1;36m EJEMPLOS COMBINADOS\033[0m"
    echo -e "  \033[1;33md_help\033[0m           ➤ Ver la ayuda completa del script"
    echo -e "  \033[1;33md_all\033[0m            ➤ Ejecutar absolutamente todo sin confirmaciones"
    echo -e "  \033[1;33md_step\033[0m           ➤ Ejecutar paso a paso, confirmando cada bloque"
    echo -e "  \033[1;33md_debug\033[0m          ➤ Mostrar todas las variables antes de ejecutar"

    echo -e "\n  \033[1;33md_local\033[0m          ➤ Despliegue local completo sin Heroku ni VPS"
    echo -e "  \033[1;33md_heroku\033[0m         ➤ Sincronizar archivos y subir solo a Heroku"
    echo -e "  \033[1;33md_production\033[0m     ➤ Despliegue para VPS Njalla (sin Heroku)"

    echo -e "\n  \033[1;33md_reset_full\033[0m     ➤ Reinstalación completa del entorno"
    echo -e "  \033[1;33md_sync\033[0m           ➤ Solo sincronizar archivos locales sin otras acciones"

    echo -e "\n  \033[1;33md_push_heroku\033[0m    ➤ Ejecutar solo push a GitHub + Heroku"
    echo -e "  \033[1;33md_njalla\033[0m          ➤ Subida directa al VPS Njalla (coretransapi.com)"

    echo -e "\n  \033[1;33mdeploy_menu\033[0m      ➤ Menú interactivo con FZF para seleccionar despliegue"

    echo -e "\n\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m\n"

    echo -e ""
}

# === PARSEO DE ARGUMENTOS ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)               PROMPT_MODE=false ;;
        -s|--step)              PROMPT_MODE=true ;;
        -B|--omit-bdd)          OMIT_SYNC_REMOTE_DB=true ;;
        -H|--omit-heroku)       OMIT_HEROKU=true ;;
        -G|--omit-gunicorn)     OMIT_GUNICORN=true ;;
        -L|--omit-local)        OMIT_JSON_LOCAL=true ;;
        -S|--omit-sync)         OMIT_SYNC_LOCAL=true ;;
        -D|--omit-docker)       OMIT_DOKER=true ;;
        -P|--omit-ports)        OMIT_PORTS=true ;;
        -Y|--omit-sys)          OMIT_SYS=true ;;
        -Z|--omit-zip)          OMIT_ZIP_SQL=true ;;
        -M|--omit-mac)          OMIT_MAC=true ;;
        -p|--omit-pem)          OMIT_PEM=true ;;    
        -x|--omit-ufw)          OMIT_UFW=true ;;
        -U|--omit-create-user)  OMIT_USER=true ;;
        -l|--omit-load-local)   OMIT_RUN_LOCAL=true ;;
        -w|--omit-web)          OMIT_RUN_WEB=true ;;
        -C|--omit-clean)        OMIT_CLEAN=true ;;
        -V|--omit-verif-trans)  OMIT_VERIF_TRANSF=true ;;
        -v|--omit-vps)          OMIT_DEPLOY_VPS=true ;;
        -d|--debug)             DEBUG_MODE=true ;;
        -h|--help)              usage; exit 0 ;;
        *)
            echo -e "\033[1;31m❌ Opción desconocida:\033[0m $1"
            usage
            exit 1
            ;;
    esac
    shift
done

# === FUNCIÓN CONFIRMAR ===
confirmar() {
    [[ "$PROMPT_MODE" == false ]] && return 0
    echo
    printf "\033[1;34m🔷 ¿Confirmas: %s? (s/n):\033[0m " "$1"
    read -r resp
    [[ "$resp" =~ ^[sS]$ || -z "$resp" ]]
    echo ""
}

# === SOLICITAR COMENTARIO PARA COMMIT SI NO SE OMITE HEROKU ===
if [[ "$OMIT_HEROKU" == false ]]; then
    echo -e "\033[1;30m🔐 Se solicitarán privilegios sudo para operaciones posteriores...[0m"
    sudo -v

    if [[ -z "${COMENTARIO_COMMIT:-}" ]]; then
        echo -e "\033[7;30m✏️ Ingrese el comentario del commit (se usará más adelante):\033[0m"
        read -rp "📝 Comentario: " COMENTARIO_COMMIT
        if [[ -z "$COMENTARIO_COMMIT" ]]; then
            echo -e "\033[1;31m❌ Comentario vacío. Abortando ejecución.\033[0m"
            exit 1
        fi
    else
        echo -e "\033[1;32m📝 Usando comentario exportado: \033[0m$COMENTARIO_COMMIT"
    fi
    export COMENTARIO_COMMIT
fi



if [[ "${DEBUG_MODE:-false}" == true ]]; then
    echo "=== VARIABLES ACTUALES ==="
    env | grep -E "DB_|PROJECT_ROOT|HEROKU_ROOT|OMIT_|PROMPT_|INTERFAZ"
    echo "=========================="
fi



# === FUNCIONES PROFESIONALES ===
verificar_vpn_segura() {
    if ip a show proton0 &>/dev/null; then
        log_ok "VPN (proton0) activa. Conexión segura."
    elif ip a show tun0 &>/dev/null; then
        log_ok "VPN (tun0) activa. Conexión segura."
    else
        log_error "❌ No hay VPN activa (ni proton0 ni tun0). Abortando despliegues sensibles."
        exit 1
    fi
}

rotar_logs_si_grandes() {
    for file in "$LOGS_DIR"/*.log; do
        [[ ! -f "$file" ]] && continue
        size=$(du -m "$file" | cut -f1)
        if [[ "$size" -ge 10 ]]; then
            ts=$(date +%Y%m%d_%H%M%S)
            mv "$file" "$file.$ts"
            touch "$file"
            log_info "🌀 Log $file archivado por tamaño (>$size MB)"
        fi
    done
}

verificar_configuracion_segura() {
    archivo_env="$PROJECT_ROOT/.env"
    if grep -q "DEBUG=True" "$archivo_env"; then
        log_error "❌ DEBUG está activo en producción. Revisa tu .env"
        exit 1
    fi
    if grep -q "localhost" "$archivo_env"; then
        log_error "❌ ALLOWED_HOSTS contiene 'localhost'. No es seguro para producción."
        exit 1
    fi
    if ! grep -q "SECRET_KEY=" "$archivo_env"; then
        log_error "❌ SECRET_KEY no está configurado en .env"
        exit 1
    fi
    log_ok "✔️ Configuración .env validada."
}

ver_ip_publica() {
    local ip=$(curl -s ifconfig.me || echo "N/D")
    echo -e "\033[1;36m🌐 IP pública actual: $ip\033[0m"
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
# diagnostico_entorno

echo ""
echo ""
echo ""
sleep 3
# clear

echo -e "\033[7;33m----------------------------------------------SISTEMA----------------------------------------------\033[0m"
if [[ "$OMIT_SYS" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Actualizar sistema"); then
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

echo -e "\033[7;33m--------------------------------------------------ZIP----------------------------------------------\033[0m"
if [[ "$OMIT_ZIP_SQL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear zip y sql"); then
    echo -e "\033[7;30mCreando ZIP archivos al destino...\033[0m"
    bash $HOME/Documentos/GitHub/api_bank_h2/scripts/15_zip_backup.sh
    
    # PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
    # PROJECT_BASE_DIR="$HOME/Documentos/GitHub"
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
# clear

echo -e "\033[7;33m----------------------------------------------PUERTOS----------------------------------------------\033[0m"
if [[ "$OMIT_PORTS" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Detener puertos abiertos"); then
    PUERTOS_OCUPADOS=0
    for PUERTO in 2222 8000 5000 8001 35729; do
        if lsof -i tcp:"$PUERTO" &>/dev/null; then
            PUERTOS_OCUPADOS=$((PUERTOS_OCUPADOS + 1))
            if confirmar "Cerrar procesos en puerto $PUERTO"; then
                sudo fuser -k "${PUERTO}"/tcp || true
                echo -e "\033[7;30m✅ Puerto $PUERTO liberado.\033[0m"
                echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
                echo ""
            fi
        fi
    done
    if [ "$PUERTOS_OCUPADOS" -eq 0 ]; then
        echo -e "\033[7;31m🚫 No se encontraron procesos en los puertos definidos.\033[0m"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
        echo ""
    fi
fi

echo ""
echo ""
echo ""
sleep 3
# clear

echo -e "\033[7;33m--------------------------------------------CONTENEDORES-------------------------------------------\033[0m"
if [[ "$OMIT_DOKER" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Detener contenedores Docker"); then
    PIDS=$(docker ps -q)
    if [ -n "$PIDS" ]; then
        docker stop $PIDS
        echo -e "\033[7;30m🐳 Contenedores detenidos.\033[0m"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
        echo ""
    else
        echo -e "\033[7;30m🐳 No hay contenedores.\033[0m"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
        echo ""
    fi
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

echo -e "\033[7;33m------------------------------------------------UFW------------------------------------------------\033[0m"
if [[ "$OMIT_UFW" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Configurar venv y PostgreSQL"); then
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
    sudo ufw allow out to any port 443 #PUSH
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

echo -e "\033[7;33m----------------------------------------------POSTGRES---------------------------------------------\033[0m"
if [[ "$OMIT_PGSQL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Configurar venv y PostgreSQL"); then
    # python3 -m venv "$VENV_PATH"
    # source "$VENV_PATH/bin/activate"
    # pip install --upgrade pip
    # echo "📦 Instalando dependencias..."
    # echo ""
    # pip install -r "$PROJECT_ROOT/requirements.txt"
    # echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    # echo ""
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    echo -e "\033[7;30m🐍 Entorno y PostgreSQL listos.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""

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
if [[ "$OMIT_MIG" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Ejecutar migraciones"); then
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
    echo ""

fi

echo ""
echo ""
echo ""
sleep 3
# clear


echo -e "\033[7;33m--------------------------------------------CARGAR LOCAL-------------------------------------------\033[0m"
if [[ "$OMIT_RUN_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir bdd_local"); then
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


echo -e "\033[7;33m----------------------------------------------PEM JWKS---------------------------------------------\033[0m"
if [[ "$OMIT_PEM" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Generar PEM JWKS"); then
    echo -e "\033[7;30m🚀 Generando PEM...\033[0m"
    python3 manage.py genkey
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 3
# clear

echo -e "\033[7;33m--------------------------------------VERIFICAR TRANSFERENCIAS-------------------------------------\033[0m"
if [[ "$OMIT_VERIF_TRANSF" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Verificar archivos transferencias"); then
    echo -e "\033[7;30m🚀 Verificando logs transferencias...\033[0m"
    python manage.py verificar_transferencias --fix -c -j
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 3
# clear

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
        api_bank_h2)
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

verificar_vpn_segura
verificar_configuracion_segura

echo -e "\033[7;33m-------------------------------------------SUBIR A HEROKU------------------------------------------\033[0m"
if [[ "$OMIT_HEROKU" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir el proyecto a la web"); then

    echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
    cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    # Configurar variable DJANGO_SETTINGS_MODULE
    echo -e "\033[7;36m🔧 Configurando DJANGO_SETTINGS_MODULE en Heroku...\033[0m"
    heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production
    # CLAVE_SEGURA=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(64)))")
    heroku config:set DJANGO_SECRET_KEY=$SECRET_KEY
    heroku config:set DJANGO_DEBUG=False
    heroku config:set DJANGO_ALLOWED_HOSTS=*.herokuapp.com
    # heroku config:set DB_CLIENT_ID=tu-client-id-herokuPtf8454Jd55
    # heroku config:set DB_CLIENT_SECRET=tu-client-secret-heroku
    heroku config:set DB_TOKEN_URL=https://simulator-api.db.com:443/gw/dbapi/token
    heroku config:set DB_AUTH_URL=https://simulator-api.db.com:443/gw/dbapi/authorize
    heroku config:set DB_API_URL=https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer
    heroku config:set DB_SCOPE=sepa_credit_transfers
    heroku config:set API_ORIGIN=https://api.db.com
    heroku config:set TIMEOUT_REQUEST=3600
    heroku config:set DISABLE_COLLECTSTATIC=1
    set -a; source .env; set +a
    heroku config:set PRIVATE_KEY_B64=$(base64 -w 0 schemas/keys/ecdsa_private_key.pem)
    heroku config:get PRIVATE_KEY_B64 | base64 -d | head




#     # heroku config:set PRIVATE_KEY_B64="$(cat ghost.key.b64)"
#     # echo -e "\033[7;36m🔐 Verificando y generando clave privada JWT...\033[0m"
#     # # Crear carpeta keys/ si no existe
#     # mkdir -p keys
#     # # Ruta esperada del archivo
#     # PEM_PATH="$HOME/Documentos/GitHub/api_bank_h2/schemas/keys/ecdsa_private_key.pem"
#     # # Verificar existencia de la clave privada
#     # if [[ ! -f "$PEM_PATH" ]]; then
#     #     echo -e "\033[7;33m⚠️  Clave privada no encontrada. Generando clave ECDSA P-256...\033[0m"
#     #     openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$PEM_PATH"
#     #     echo -e "\033[7;32m✅ Clave privada generada en $PEM_PATH\033[0m"
#     # else
#     #     echo -e "\033[7;32m🔎 Clave privada ya existente.\033[0m"
#     # fi
#     # # Validar contenido del archivo
#     # if ! grep -q "BEGIN PRIVATE KEY" "$PEM_PATH"; then
#     #     echo -e "\033[7;31m❌ Error: El archivo $PEM_PATH no contiene una clave privada válida.\033[0m"
#     #     exit 1
#     # fi
#     # # Configurar PRIVATE_KEY_PATH si aún no está en Heroku
#     # if [[ -z "$(heroku config:get PRIVATE_KEY_PATH)" ]]; then
#     #     echo -e "\033[7;36m🔧 Configurando PRIVATE_KEY_PATH en Heroku...\033[0m"
#     #     heroku config:set PRIVATE_KEY_PATH="$PEM_PATH"
#     # else
#     #     echo -e "\033[7;32m✅ PRIVATE_KEY_PATH ya está configurado en Heroku.\033[0m"
#     # fi
#     # # Configurar PRIVATE_KEY_KID si aún no está
#     # if [[ -z "$(heroku config:get PRIVATE_KEY_KID)" ]]; then
#     #     echo -e "\033[7;36m🔑 Generando PRIVATE_KEY_KID aleatorio...\033[0m"
#     #     PRIVATE_KEY_KID=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(32)))")
#     #     heroku config:set PRIVATE_KEY_KID="$PRIVATE_KEY_KID"
#     #     echo -e "\033[7;32m✅ PRIVATE_KEY_KID generado y configurado correctamente\033[0m"
#     # else
#     #     echo -e "\033[7;32m✅ PRIVATE_KEY_KID ya está configurado en Heroku.\033[0m"
#     # fi



    heroku config:set OAUTH2_REDIRECT_URI=https://apibank2-d42d7ed0d036.herokuapp.com/oauth2/callback/
    echo -e "\033[7;30mHaciendo git add...\033[0m"
    git add --all
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
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

echo -e "\033[7;33m---------------------------------------SINCRONIZACION BDD WEB--------------------------------------\033[0m"
if [[ "$OMIT_SYNC_REMOTE_DB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir las bases de datos a la web"); then
    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="${BACKUP_DIR}backup_${DATE}.sql"
    export PGPASSFILE="$HOME/.pgpass"
    export PGUSER="$DB_USER"
    export PGHOST="$DB_HOST"
    DB_NAME="mydatabase"
    DB_USER="markmur88"
    DB_PASS="Ptf8454Jd55"
    DB_HOST="localhost"
    REMOTE_DB_URL="postgres://u5n97bps7si3fm:pb87bf621ec80bf56093481d256ae6678f268dc7170379e3f74538c315bd549e0@c7lolh640htr57.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/dd3ico8cqsq6ra"
    
    if ! command -v pv > /dev/null 2>&1; then
        log_error "❌ La herramienta 'pv' no está instalada. Instálala con: sudo apt install pv"
        exit 1
    fi

    log_info "🧹 Reseteando base de datos remota (DROP SCHEMA)..."
    echo "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" | psql "$REMOTE_DB_URL" 2>&1 
    check_status "DROP y CREATE SCHEMA remoto"

    log_info "📦 Generando backup local con pg_dump..."
    ejecutar pg_dump --no-owner --no-acl -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" > "$BACKUP_FILE"
    log_ok "📄 Backup SQL generado: $BACKUP_FILE"

    log_info "📤 Subiendo backup a la base de datos remota con pv + psql..."
    pv "$BACKUP_FILE" | psql "$REMOTE_DB_URL" >> "$LOG_FILE_SCRIPT" 2>&1
    check_status "Importación a DB remota"

    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"
    log_ok "✅ Sincronización completada correctamente"
    echo -e "\033[7;30m✅ Sincronización completada con éxito: $BACKUP_FILE\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""

fi

echo ""
echo ""
echo ""
sleep 3
# clear

echo -e "\033[7;33m---------------------------------DEPLOY REMOTO A VPS - CORETRANSAPI--------------------------------\033[0m"
if [[ "$OMIT_DEPLOY_VPS" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "¿Desplegar api_bank_h2 en VPS Njalla?"); then
    echo -e "\n\033[1;36m🌐 Desplegando api_bank_h2 en VPS Njalla...\033[0m"

    if ! bash "${SCRIPTS_DIR}/21_deploy_ghost_njalla.sh" >> "$STARTUP_LOG" 2>&1; then
        echo -e "\033[1;31m⚠️ Fallo en el primer intento de deploy. Ejecutando instalación de dependencias...\033[0m"
        bash "${SCRIPTS_DIR}/vps_instalar_dependencias.sh" >> "$STARTUP_LOG" 2>&1
        echo -e "\033[1;36m🔁 Reintentando despliegue...\033[0m"
        if ! bash "${SCRIPTS_DIR}/21_deploy_ghost_njalla.sh" >> "$STARTUP_LOG" 2>&1; then
            echo -e "\033[1;31m❌ Fallo final en despliegue remoto. Consulta logs en $STARTUP_LOG\033[0m"
            exit 1
        fi
    fi

    echo -e "\033[1;32m✅ Despliegue remoto al VPS completado.\033[0m"
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
    BACKUP_DIR=$HOME/Documentos/GitHub/backup
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
echo ""
sleep 3
# clear

echo -e "\033[7;33m---------------------------------------------CAMBIO MAC--------------------------------------------\033[0m"
if [[ "$OMIT_MAC" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Cambiar MAC de la interfaz $INTERFAZ"); then
    echo -e "\033[7;30mCambiando MAC de la interfaz $INTERFAZ\033[0m"
    ver_ip_publica
    sudo ip link set "$INTERFAZ" down
    MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
    MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
    sudo ip link set "$INTERFAZ" up
    ver_ip_publica
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

verificar_vpn_segura
rotar_logs_si_grandes


echo -e "\033[7;33m---------------------------------------------- GUNICORN ----------------------------------------------\033[0m"

# === CONFIGURACIÓN ===
PUERTOS=(8001 5000 35729)
URL_LOCAL="http://localhost:5000"
URL_GUNICORN="http://127.0.0.1:8001"
URL_HEROKU="https://apibank2-d42d7ed0d036.herokuapp.com/"
LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

# === FUNCIONES ===
liberar_puertos() {
    for port in "${PUERTOS[@]}"; do
        if lsof -i :$port &>/dev/null; then
            echo -e "\033[1;34m🔌 Liberando puerto $port...\033[0m"
            kill $(lsof -t -i :$port) &>/dev/null || true
        fi
    done
}

limpiar_y_salir() {
    echo -e "\n\033[1;33m🧹 Deteniendo todos los servicios...\033[0m"
    pkill -f "gunicorn" &>/dev/null || true
    pkill -f "honeypot.py" &>/dev/null || true
    pkill -f "livereload" &>/dev/null || true
    [ -n "${FIREFOX_PID:-}" ] && kill "$FIREFOX_PID" 2>/dev/null || true
    liberar_puertos
    echo -e "\033[1;32m✅ Todos los servicios detenidos.\033[0m"
    echo -e "$LOGO_SEP\n"
    exit 0
}

iniciar_entorno() {
    echo -e "\033[1;36m📦 Activando entorno virtual y configuración...\033[0m"
    cd "$PROJECT_ROOT"
    source "$VENV_PATH/bin/activate"
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    python manage.py collectstatic --noinput
}

verificar_seguridad() {
    if [[ "$ENVIRONMENT" != "local" ]]; then
        echo -e "\033[1;31m🔒 Verificando conexión segura: VPN + Tor...\033[0m"
        if ! curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org | grep -q "Congratulations"; then
            echo -e "\033[1;31m❌ Error: No estás conectado por Tor. Abortando por seguridad.\033[0m"
            exit 1
        fi
        echo -e "\033[1;32m✅ Tor activo. Entorno seguro.\033[0m"
    fi
}



# === INICIO GUNICORN + HONEYPOT ===
if [[ "${OMIT_GUNICORN:-false}" == false ]] && ([[ "${PROMPT_MODE:-false}" == false ]] || confirmar "¿Iniciar Gunicorn, honeypot y livereload?"); then
    echo -e "\033[7;30m🚀 Iniciando Gunicorn, honeypot y livereload...\033[0m"
    trap limpiar_y_salir SIGINT
    verificar_seguridad
    liberar_puertos
    iniciar_entorno

    echo -e "\n🔧 Configurando Gunicorn con systemd...\n"
    {
        bash "${SCRIPTS_DIR}/configurar_gunicorn.sh"
        echo -e "✅ Gunicorn configurado correctamente.\n"
    } >> "$STARTUP_LOG" 2>&1 || {
        echo -e "\033[1;31m❌ Error al configurar Gunicorn. Consulta $STARTUP_LOG\033[0m"
        exit 1
    }

    echo -e "\033[1;34m🌀 Lanzando servicios secundarios...\033[0m"
    nohup python honeypot.py > "$LOG_DIR/honeypot.log" 2>&1 < /dev/null &
    nohup livereload --host 127.0.0.1 --port 35729 static/ -t templates/ > "$LOG_DIR/livereload.log" 2>&1 < /dev/null &

    sleep 3
    firefox --new-window "$URL_LOCAL" --new-tab "https://api.coretransapi.com" --new-tab "$URL_HEROKU" &
    FIREFOX_PID=$!

    echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
    echo -e "$LOGO_SEP\n"
    while true; do sleep 3; done
fi

echo ""
echo ""
echo ""
sleep 3
# clear

# echo -e "\033[7;33m----------------------------------------------GUNICORN---------------------------------------------\033[0m"
# # === CONFIGURACIÓN ===
# PUERTOS=(8001 5000 35729)
# URL_LOCAL="http://localhost:5000"
# URL_GUNICORN="http://0.0.0.0:8011"
# URL_HEROKU="https://apibank2-d42d7ed0d036.herokuapp.com/"
# LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
# # === FUNCIONES ===
# liberar_puertos() {
#     for port in "${PUERTOS[@]}"; do
#         if lsof -i :$port > /dev/null; then
#             echo -e "\033[1;34m🔌 Liberando puerto $port...\033[0m"
#             kill $(lsof -t -i :$port) 2>/dev/null || true
#         fi
#     done
# }
# limpiar_y_salir() {
#     echo -e "\n\033[1;33m🧹 Deteniendo todos los servicios...\033[0m"
#     pids=$(jobs -p)
#     [ -n "$pids" ] && kill $pids 2>/dev/null
#     [ -n "$FIREFOX_PID" ] && kill "$FIREFOX_PID" 2>/dev/null || true
#     liberar_puertos
#     echo -e "\033[1;32m✅ Todos los servicios detenidos.\033[0m"
#     echo -e "$LOGO_SEP\n"
#     exit 0
# }
# iniciar_entorno() {
#     cd "$PROJECT_ROOT"
#     source "$VENV_PATH/bin/activate"
#     python manage.py collectstatic --noinput
#     export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
# }
# # === INICIO GUNICORN + HONEYPOT ===
# if [[ "$OMIT_GUNICORN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Iniciar Gunicorn, honeypot y livereload"); then
#     echo -e "\033[7;30m🚀 Iniciando Gunicorn, honeypot y livereload...\033[0m"
#     trap limpiar_y_salir SIGINT
#     liberar_puertos
#     iniciar_entorno
#     nohup "$VENV_PATH/bin/gunicorn" config.wsgi:application --workers 3 --bind 127.0.0.1:8001 --keep-alive 2 > "$LOGS_DIR/gunicorn_api.log" 2>&1 < /dev/null &
#     nohup python honeypot.py > "$LOGS_DIR/honeypot.log" 2>&1 < /dev/null &
#     nohup livereload --host 127.0.0.1 --port 35729 static/ -t templates/ > "$LOGS_DIR/livereload.log" 2>&1 < /dev/null &   
#     sleep 3
#     firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN" --new-tab "$URL_HEROKU" &
#     FIREFOX_PID=$!
#     echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
#     echo -e "$LOGO_SEP\n"
#     while true; do sleep 3; done
# fi
# echo ""

# echo ""
# echo ""
# echo ""
# sleep 3
# # clear

# verificar_vpn_segura

# # === ABRIR WEB HEROKU ===
# echo -e "\033[7;33m---------------------------------------------CARGAR WEB--------------------------------------------\033[0m"
# if [[ "$OMIT_RUN_WEB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Abrir web Heroku"); then
#     echo -e "\033[7;30m🌐 Abriendo web de Heroku...\033[0m"
#     trap limpiar_y_salir SIGINT
#     liberar_puertos
#     iniciar_entorno
#     firefox --new-window "$URL_HEROKU" &
#     FIREFOX_PID=$!
#     echo -e "\033[7;30m🚧 Web Heroku activa. Ctrl+C para cerrar.\033[0m"
#     echo -e "$LOGO_SEP\n"
#     while true; do sleep 3; done
# fi
# echo ""

echo ""
echo ""
echo ""
sleep 3
# clear

# === FIN: CORREGIDO EL BLOQUE PROBLEMÁTICO ===
URL="$URL_LOCAL"
notify-send "api_bank_h2" "✅ Proyecto iniciado correctamente en:
$URL
$URL_HEROKU
🏁 ¡Todo completado con éxito!
✅ Sincronización completada con éxito: $BACKUP_FILE
📦 Commit con el mensaje: $COMENTARIO_COMMIT
log_info "🗂 Log disponible en: $LOG_FILE_SCRIPT"

