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

# ╔══════════════════════════════════════════════════════════╗
# ║                    SCRIPT MAESTRO DE DESPLIEGUE - api_bank_h2           ║
# ║  Automatización total: setup, backups, deploy, limpieza y seguridad       ║
# ║  Soporte para 30 combinaciones de despliegue con alias `d_*`              ║
# ║  Ejecuta `deploy_menu` para selección interactiva con FZF                 ║
# ║  Ejecuta `d_help` para ver ejemplos combinados y sus parámetros           ║
# ║  Autor: markmur88                                                         ║
# ╚══════════════════════════════════════════════════════════╝

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
PROJECT_ROOT="/home/markmur88/Documentos/GitHub/api_bank_h2"
HEROKU_ROOT="/home/markmur88/Documentos/GitHub/api_bank_h2"
NJALLA_ROOT="/home/markmur88/Documentos/GitHub/coretransapi"
VENV_PATH="/home/markmur88/Documentos/Entorno/envAPP"
INTERFAZ="wlan0"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE_SCRIPT="$LOG_DIR/full_deploy.log"
STARTUP_LOG="$LOG_DIR/startup.log"


# === CREDENCIALES BASE DE DATOS ===
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="0.0.0.0"

# === FLAGS DE CONTROL DE BLOQUES ===
PROMPT_MODE=false
DEBUG_MODE=true       # 00
DO_SYS=true           # 01
DO_ZIP_SQL=true       # 02
DO_PORTS=true         # 03
DO_DOKER=true         # 04
DO_MAC=true           # 05
DO_JSON_LOCAL=true    # 06
DO_UFW=true           # 07
DO_PGSQL=true         # 08
DO_MIG=true           # 09
DO_RUN_LOCAL=true     # 10
DO_USER=true          # 11
DO_PEM=true           # 12
DO_VERIF_TRANSF=true  # 13
DO_SYNC_LOCAL=true    # 14
DO_VARHER=true        # 15
DO_HEROKU=true        # 16
DO_SYNC_REMOTE_DB=true  # 17
DO_DEPLOY_VPS=true    # 18
DO_CLEAN=true         # 19
DO_GUNICORN=true      # 20
DO_RUN_WEB=true       # 21
DO_LOCAL_SSL=false    # 22  # 🚀 NUEVO: ejecutar entorno local con HTTPS real (Nginx + Gunicorn 8443)


if [[ "$@" =~ -[Y-Zy-z] ]]; then
    PROMPT_MODE=false
fi

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

# === PARÁMETRO DE ENTORNO --env ===
for arg in "$@"; do
  if [[ "$arg" == --env=* ]]; then
    ENTORNO="${arg#*=}"
    echo -e "🌐 Entorno seleccionado: $ENTORNO"
    export DJANGO_ENV="$ENTORNO"
    break
  fi
done

usage() {
    echo -e "\n\033[1;36mUSO:\033[0m"
    echo -e "  bash ./01_full.sh [opciones]\n"

    echo -e "\033[1;33mOPCIONES DISPONIBLES:\033[0m"
    echo -e "  \033[1;33m-a\033[0m, \033[1;33m--all\033[0m               Ejecutar sin confirmaciones interactivas"
    echo -e "  \033[1;33m-s\033[0m, \033[1;33m--step\033[0m              Activar modo paso a paso (pregunta todo)"
    echo -e "  \033[1;33m-d\033[0m, \033[1;33m--debug\033[0m              Mostrar diagnóstico y variables actuales"
    echo -e "  \033[1;33m-h\033[0m, \033[1;33m--help\033[0m               Mostrar esta ayuda y salir"

    echo -e "\n\033[1;33mTAREAS DE DESARROLLO LOCAL:\033[0m"
    echo -e "  \033[1;33m-L\033[0m, \033[1;33m--do-local\033[0m          Cargar archivos locales .json/.env"
    echo -e "  \033[1;33m-l\033[0m, \033[1;33m--do-load-local\033[0m     Ejecutar entorno local estándar"
    echo -e "  \033[1;33m-r\033[0m, \033[1;33m--do-local-ssl\033[0m      Ejecutar entorno local con SSL (Gunicorn + Nginx 8443) 🚀"

    echo -e "\n\033[1;33mBACKUPS Y DEPLOY:\033[0m"
    echo -e "  \033[1;33m-C\033[0m, \033[1;33m--do-clean\033[0m          Limpiar respaldos antiguos"
    echo -e "  \033[1;33m-Z\033[0m, \033[1;33m--do-zip\033[0m            Generar backups ZIP + SQL"
    echo -e "  \033[1;33m-B\033[0m, \033[1;33m--do-bdd\033[0m            Sincronizar BDD remota"
    echo -e "  \033[1;33m-H\033[0m, \033[1;33m--do-heroku\033[0m         Desplegar a Heroku"
    echo -e "  \033[1;33m-v\033[0m, \033[1;33m--do-vps\033[0m            Desplegar a VPS (Njalla)"
    echo -e "  \033[1;33m-S\033[0m, \033[1;33m--do-sync\033[0m           Sincronizar archivos locales"

    echo -e "\n\033[1;33mENTORNO Y CONFIGURACIÓN:\033[0m"
    echo -e "  \033[1;33m-Y\033[0m, \033[1;33m--do-sys\033[0m            Actualizar sistema y dependencias"
    echo -e "  \033[1;33m-P\033[0m, \033[1;33m--do-ports\033[0m          Cerrar puertos abiertos conflictivos"
    echo -e "  \033[1;33m-M\033[0m, \033[1;33m--do-mac\033[0m            Cambiar MAC aleatoria"
    echo -e "  \033[1;33m-x\033[0m, \033[1;33m--do-ufw\033[0m            Configurar firewall UFW"
    echo -e "  \033[1;33m-p\033[0m, \033[1;33m--do-pem\033[0m            Generar claves PEM locales"
    echo -e "  \033[1;33m-U\033[0m, \033[1;33m--do-create-user\033[0m    Crear usuario del sistema"
    echo -e "  \033[1;33m-u\033[0m, \033[1;33m--do-varher\033[0m         Configurar variables Heroku"

    echo -e "\n\033[1;33mPOSTGRES Y MIGRACIONES:\033[0m"
    echo -e "  \033[1;33m-Q\033[0m, \033[1;33m--do-pgsql\033[0m          Configurar PostgreSQL local"
    echo -e "  \033[1;33m-I\033[0m, \033[1;33m--do-migra\033[0m          Aplicar migraciones Django"

    echo -e "\n\033[1;33mEJECUCIÓN Y TESTING:\033[0m"
    echo -e "  \033[1;33m-G\033[0m, \033[1;33m--do-gunicorn\033[0m       Ejecutar Gunicorn"
    echo -e "  \033[1;33m-w\033[0m, \033[1;33m--do-web\033[0m            Abrir navegador automáticamente"
    echo -e "  \033[1;33m-V\033[0m, \033[1;33m--do-verif-trans\033[0m    Verificar transferencias SEPA"
}



# === PARSEO DE ARGUMENTOS ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)             PROMPT_MODE=false ;;
        -s|--step)            PROMPT_MODE=true ;;
        -B|--do-bdd)          DO_SYNC_REMOTE_DB=true ;;
        -H|--do-heroku)       DO_HEROKU=true ;;
        -u|--do-varher)       DO_VARHER=true ;;
        -G|--do-gunicorn)     DO_GUNICORN=true ;;
        -C|--do-clean)        DO_CLEAN=true ;;
        -L|--do-local)        DO_JSON_LOCAL=true ;;
        -S|--do-sync)         DO_SYNC_LOCAL=true ;;
        -D|--do-docker)       DO_DOKER=true ;;
        -P|--do-ports)        DO_PORTS=true ;;
        -Y|--do-sys)          DO_SYS=true ;;
        -Z|--do-zip)          DO_ZIP_SQL=true ;;
        -M|--do-mac)          DO_MAC=true ;;
        -I|--do-migra)        DO_MIG=true ;;
        -Q|--do-pgsql)        DO_PGSQL=true ;;
        -p|--do-pem)          DO_PEM=true ;;    
        -x|--do-ufw)          DO_UFW=true ;;
        -U|--do-create-user)  DO_USER=true ;;
        -l|--do-load-local)   DO_RUN_LOCAL=true ;;
        -w|--do-web)          DO_RUN_WEB=true ;;
        -V|--do-verif-trans)  DO_VERIF_TRANSF=true ;;
        -v|--do-vps)          DO_DEPLOY_VPS=true ;;
        -d|--debug)           DEBUG_MODE=true ;;
        -r|--do-local-ssl)    DO_LOCAL_SSL=true ;;  # 🚀 NUEVO FLAG
        -h|--help)            usage; exit 0 ;;
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
if [[ "$DO_HEROKU" == true ]]; then
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
    echo ""
    echo -e "\033[1;36m============================= VARIABLES ACTUALES =============================\033[0m"
    printf "%-20s =\t%s\n" "INTERFAZ"            "$INTERFAZ"
    printf "%-20s =\t%s\n" "SCRIPTS_DIR"         "$PROJECT_ROOT/scripts"
    printf "%-20s =\t%s\n" "PRIVATE_KEY_PATH"    "$PROJECT_ROOT/schemas/keys/ecdsa_private_key.pem"
    printf "%-20s =\t%s\n" "SERVERS_DIR"         "$PROJECT_ROOT/servers"
    printf "%-20s =\t%s\n" "CACHE_DIR"           "$PROJECT_ROOT/tmp"
    printf "%-20s =\t%s\n" "PROJECT_ROOT"        "$PROJECT_ROOT"
    printf "%-20s =\t%s\n" "LOG_DIR"             "$PROJECT_ROOT/logs"
    echo -e "\033[1;36m==============================================================================\033[0m"
    echo ""
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
    for file in "$LOG_DIR"/*.log; do
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
    if grep -q "0.0.0.0" "$archivo_env"; then
        log_error "❌ ALLOWED_HOSTS contiene '0.0.0.0'. No es seguro para producción."
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

ejecutar_si_activo() {
    local flag_nombre="$1"
    local mensaje_confirmacion="$2"
    local accion="$3"

    # Usa eval para evaluar variables dinámicas como DO_XXX
    local flag_valor
    flag_valor=$(eval echo "\$$flag_nombre")

    if [[ "$flag_valor" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "$mensaje_confirmacion"); then
        eval "$accion"
    fi
}

# === LLAMAR AL DIAGNÓSTICO TEMPRANO ===
# diagnostico_entorno

echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m------------------------------------------------SISTEMA------------------------------------------------\033[0m"
if [[ "$DO_SYS" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Actualizar sistema"); then
    sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean
    echo -e "\033[7;30m🔄 Sistema actualizado.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m----------------------------------------------------ZIP------------------------------------------------\033[0m"
if [[ "$DO_ZIP_SQL" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear zip y sql"); then
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
sleep 1
# clear

echo -e "\033[7;33m------------------------------------------------PUERTOS------------------------------------------------\033[0m"
if [[ "$DO_PORTS" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Detener puertos abiertos"); then
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
sleep 1
# clear

echo -e "\033[7;33m----------------------------------------------CONTENEDORES---------------------------------------------\033[0m"
if [[ "$DO_DOKER" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Detener contenedores Docker"); then
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
sleep 1
# clear


echo -e "\033[7;33m-----------------------------------------------CAMBIO MAC----------------------------------------------\033[0m"
if [[ "$DO_MAC" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Cambiar MAC de la interfaz $INTERFAZ"); then
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
sleep 1
# clear



echo -e "\033[7;33m--------------------------------------------------UFW--------------------------------------------------\033[0m"
if [[ "$DO_UFW" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Configurar venv y PostgreSQL"); then
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
sleep 1
# clear

echo -e "\033[7;33m------------------------------------------------POSTGRES-----------------------------------------------\033[0m"
if [[ "$DO_PGSQL" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Configurar venv y PostgreSQL"); then
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

    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"
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
sleep 1
# clear

echo -e "\033[7;33m----------------------------------------------MIGRACIONES----------------------------------------------\033[0m"
if [[ "$DO_MIG" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Ejecutar migraciones"); then
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
sleep 1
# clear


echo -e "\033[7;33m----------------------------------------------CARGAR LOCAL---------------------------------------------\033[0m"
if [[ "$DO_RUN_LOCAL" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir bdd_local"); then
    echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m"
    python3 manage.py loaddata bdd_local.json
    echo -e "\033[7;30m✅ ¡Subido JSON Local!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 1
# clear


echo -e "\033[7;33m------------------------------------------------USUARIO------------------------------------------------\033[0m"
if [[ "$DO_USER" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear Super Usuario"); then
    echo -e "\033[7;30m🚀 Creando usuario...\033[0m"
    python3 manage.py createsuperuser
    echo -e "\033[7;30m✅ ¡Usuario creado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m--------------------------------------------RESPALDOS LOCAL--------------------------------------------\033[0m"
if [[ "$DO_JSON_LOCAL" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear bdd_local"); then
    echo -e "\033[7;30m🚀 Creando respaldo de datos de local...\033[0m"
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"
    python3 manage.py dumpdata --indent 2 > bdd_local.json
    echo -e "\033[7;30m✅ ¡Respaldo JSON Local creado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m------------------------------------------------PEM JWKS-----------------------------------------------\033[0m"
if [[ "$DO_PEM" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Generar PEM JWKS"); then
    echo -e "\033[7;30m🚀 Generando PEM...\033[0m"
    python3 manage.py genkey
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m----------------------------------------VERIFICAR TRANSFERENCIAS---------------------------------------\033[0m"
if [[ "$DO_VERIF_TRANSF" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Verificar archivos transferencias"); then
    echo -e "\033[7;30m🚀 Verificando logs transferencias...\033[0m"
    python manage.py verificar_transferencias --fix -c -j
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m----------------------------------------SINCRONIZACION COMPLETA----------------------------------------\033[0m"
EXCLUDES=(
    "--exclude=*.zip"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    "--exclude=bin/"
    # "--exclude=scripts/"
    # "--exclude=scripts_njalla/"
    "--exclude=servers/"
    # "--exclude=tmp/"
    "--exclude=temp/"
    "--exclude=.env.heroku"
    # "--exclude=01_full.sh"
    # "--exclude=bdd_local.json"
    "--exclude=config_master.py"
    "--exclude=gunicorn.log"
    "--exclude=honey*"
    "--exclude=livereload.log"
    "--exclude=master.sh"
    "--exclude=multi_master.sh"
    "--exclude=nginx.conf"
    "--exclude=post_install_coretransapi.sh"
    "--exclude=setup_coretransact.sh"
    "--exclude=sync.sh"
    "--exclude=config/"


)

actualizar_django_env() {
    local destino="$1"
    log_info "🧾 Ajustando DJANGO_ENV en __init__.py en $destino"
    python3 <<EOF | tee -a "$LOG_FILE_SCRIPT"
import os
settings_path = os.path.join("$destino", "config", "settings", "__init__.py")
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
        print("✅ DJANGO_ENV actualizado a "'production'" en __init__.py.")
    else:
        print("⚠️ No se encontró DJANGO_ENV='local' para actualizar.")
else:
    print("⚠️ No se encontró __init__.py en el destino.")
EOF
}

if [[ "$DO_SYNC_LOCAL" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "¿Sincronizas archivos locales?"); then
    # for destino in "$HEROKU_ROOT" "$NJALLA_ROOT"; do
    for destino in "$HEROKU_ROOT" ; do
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
sleep 1
# clear

verificar_vpn_segura
verificar_configuracion_segura

echo -e "\033[7;33m-------------------------------------------VARIABLES A HEROKU------------------------------------------\033[0m"
if [[ "$DO_VARHER" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir variables a Heroku"); then

    echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
    cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    # Configurar variable DJANGO_SETTINGS_MODULE
    echo -e "\033[7;36m🔧 Configurando DJANGO_SETTINGS_MODULE en Heroku...\033[0m"
    heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production
    # CLAVE_SEGURA=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(64)))")
    heroku config:set DJANGO_SECRET_KEY=$SECRET_KEY
    heroku config:set DJANGO_DEBUG=True
    heroku config:set DJANGO_ALLOWED_HOSTS=api.coretransapi.com,apibank2-54644cdf263f.herokuapp.com,127.0.0.1,0.0.0.0
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
    heroku config:set PRIVATE_KEY_B64=$(base64 -w 0 keys/ecdsa_private_key.pem)
    heroku config:get PRIVATE_KEY_B64 | base64 -d | head
    heroku config:set OAUTH2_REDIRECT_URI=https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/
fi


#     # heroku config:set PRIVATE_KEY_B64="$(cat ghost.key.b64)"
#     # echo -e "\033[7;36m🔐 Verificando y generando clave privada JWT...\033[0m"
#     # # Crear carpeta keys/ si no existe
#     # mkdir -p keys
#     # # Ruta esperada del archivo
#     # PEM_PATH="/home/markmur88/Documentos/GitHub/api_bank_h2/schemas/keys/ecdsa_private_key.pem"
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


echo ""
echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m---------------------------------------------SUBIR A HEROKU--------------------------------------------\033[0m"
if [[ "$DO_HEROKU" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir el proyecto a la web"); then
    echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
    cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""

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
    sleep 3
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
sleep 1
# clear

echo -e "\033[7;33m-----------------------------------------SINCRONIZACION BDD WEB----------------------------------------\033[0m"
if [[ "$DO_SYNC_REMOTE_DB" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir las bases de datos a la web"); then

    echo -e "\033[7;30mSubiendo las bases de datos a la web...\033[0m"
    LOCAL_DB_NAME="mydatabase"
    LOCAL_DB_USER="markmur88"
    LOCAL_DB_HOST="0.0.0.0"
    REMOTE_DB_URL="postgres://u5n97bps7si3fm:pb87bf621ec80bf56093481d256ae6678f268dc7170379e3f74538c315bd549e0@c7lolh640htr57.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/dd3ico8cqsq6ra"

    export PGPASSFILE="/home/markmur88/.pgpass"
    export PGUSER="$LOCAL_DB_USER"
    export PGHOST="$LOCAL_DB_HOST"

    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="/home/markmur88/Documentos/GitHub/backup/sql/"
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
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 1
# clear

echo -e "\033[7;33m-----------------------------------DEPLOY REMOTO A VPS - CORETRANSAPI----------------------------------\033[0m"
if [[ "$DO_DEPLOY_VPS" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "¿Desplegar api_bank_h2 en VPS Njalla?"); then
    echo -e "\n\033[1;36m🌐 Desplegando api_bank_h2 en VPS Njalla...\033[0m"

    if ! bash "${SCRIPTS_DIR}/21_deploy_njalla.sh" "$DJANGO_ENV" >> "$STARTUP_LOG" 2>&1; then
        echo -e "\033[1;31m⚠️ Fallo en el primer intento de deploy. Ejecutando instalación de dependencias...\033[0m"
        bash "${SCRIPTS_DIR}/vps_instalar_dependencias.sh" >> "$STARTUP_LOG" 2>&1
        echo -e "\033[1;36m🔁 Reintentando despliegue...\033[0m"
        if ! bash "${SCRIPTS_DIR}/21_deploy_njalla.sh" "$DJANGO_ENV" >> "$STARTUP_LOG" 2>&1; then
            echo -e "\033[1;31m❌ Fallo final en despliegue remoto. Consulta logs en $STARTUP_LOG\033[0m"
            exit 1
        fi
    fi
    echo -e "\n\033[1;36m🔍 Verificando headers de seguridad en producción...\033[0m"
    bash "$SCRIPTS_DIR/verificar_https_headers.sh" || echo -e "\033[1;31m⚠️ Error al verificar headers\033[0m"

    echo -e "\033[1;32m✅ Despliegue remoto al VPS completado.\033[0m"
fi

echo ""
echo ""
echo ""
sleep 1
# clear

# UNO POR HORA
echo -e "\033[7;33m-------------------------------------------BORRANDO ZIP Y SQL------------------------------------------\033[0m"
if [[ "$DO_CLEAN" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Limpiar respaldos antiguos"); then
    echo -e "\033[7;30mLimpiando respaldos antiguos...\033[0m"
    echo ""

    limpiar_respaldo_por_hora() {
        local DIR="$1"
        cd "$DIR" || exit 1

        mapfile -t files < <(ls -1tr *.zip *.sql 2>/dev/null)

        declare -A keep_per_hour
        for f in "${files[@]}"; do
            name="${f%.*}"
            [[ "$name" =~ ([0-9]{8})_([0-9]{2}) ]] || continue
            clave="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}"
            keep_per_hour["$clave"]="$f"
        done

        declare -A keep
        for f in "${keep_per_hour[@]}"; do
            keep["$f"]=1
        done

        for f in "${files[@]}"; do
            if [[ -z "${keep[$f]:-}" ]]; then 
                rm -f "$f" && echo -e "\033[7;30m🗑️ Eliminado $f.\033[0m"
                echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
                echo ""
            fi
        done

        cd - >/dev/null
    }

    BACKUP_DIR_ZIP=/home/markmur88/Documentos/GitHub/backup/zip
    BACKUP_DIR_SQL=/home/markmur88/Documentos/GitHub/backup/sql

    limpiar_respaldo_por_hora "$BACKUP_DIR_ZIP"
    limpiar_respaldo_por_hora "$BACKUP_DIR_SQL"
fi

echo ""
echo ""
echo ""
sleep 1


# # PRIMERO Y ULTIMO DEL DÍA
# echo -e "\033[7;33m-------------------------------------------BORRANDO ZIP Y SQL------------------------------------------\033[0m"
# if [[ "$DO_CLEAN" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Limpiar respaldos antiguos"); then
#     echo -e "\033[7;30mLimpiando respaldos antiguos...\033[0m"
#     echo ""

#     limpiar_respaldo() {
#         local DIR="$1"
#         cd "$DIR"

#         mapfile -t files < <(ls -1tr *.zip *.sql 2>/dev/null)

#         declare -A first last keep last_hourly
#         for f in "${files[@]}"; do
#             name="${f%.*}"
#             [[ "$name" =~ ([0-9]{8})_([0-9]{2}) ]] || continue
#             fecha="${BASH_REMATCH[1]}"
#             hora="${BASH_REMATCH[2]}"
#             key_hora="${fecha}_${hora}"

#             [[ -z "${first[$fecha]:-}" ]] && first[$fecha]="$f"
#             last[$fecha]="$f"

#             today=$(date +%Y%m%d)
#             if [[ "$fecha" == "$today" ]]; then
#                 last_hourly["$key_hora"]="$f"
#             fi
#         done

#         for h in "${!last_hourly[@]}"; do
#             keep["${last_hourly[$h]}"]=1
#         done

#         yesterday=$(date -d "yesterday" +%Y%m%d)
#         [[ -n "${first[$yesterday]:-}" ]] && keep["${first[$yesterday]}"]=1
#         [[ -n "${last[$yesterday]:-}"  ]] && keep["${last[$yesterday]}"]=1

#         for d in "${!first[@]}"; do
#             if [[ "$d" != "$today" && "$d" != "$yesterday" ]]; then
#                 keep["${first[$d]}"]=1
#                 keep["${last[$d]}"]=1
#             fi
#         done

#         for f in "${files[@]}"; do
#             if [[ -z "${keep[$f]:-}" ]]; then 
#                 rm -f "$f" && echo -e "\033[7;30m🗑️ Eliminado $f.\033[0m"
#                 echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
#                 echo ""
#             fi
#         done

#         cd - >/dev/null
#     }

#     BACKUP_DIR_ZIP=/home/markmur88/Documentos/GitHub/backup/zip
#     BACKUP_DIR_SQL=/home/markmur88/Documentos/GitHub/backup/sql

#     limpiar_respaldo "$BACKUP_DIR_ZIP"
#     limpiar_respaldo "$BACKUP_DIR_SQL"
# fi

# echo ""
# echo ""
# echo ""
# sleep 1



# verificar_vpn_segura
# verificar_configuracion_segura
# rotar_logs_si_grandes



echo -e "\033[7;33m------------------------------------------------- SSL -------------------------------------------------\033[0m"
if [[ "$DO_CERT" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "¿Generar certificado local de desarrollo?"); then
    echo -e "\033[1;35m🔐 Generando certificado SSL de desarrollo...\033[0m"
    bash "/home/markmur88/Documentos/GitHub/api_bank_h2/scripts/00_generar_certificado_local.sh" || {
        echo -e "\033[1;31m❌ Error generando certificado SSL local.\033[0m"
        exit 1
    }
fi

echo ""
echo ""
echo ""
sleep 1


echo -e "\033[7;33m-----------------------------------------ENTORNO LOCAL CON SSL----------------------------------------\033[0m"
if [[ "$DO_LOCAL_SSL" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Iniciar entorno local con Gunicorn + SSL"); then
    echo -e "\033[1;36m🌐 Levantando entorno local en https://0.0.0.0:8443...\033[0m"
    bash ./scripts/run_local_ssl_env.sh || {
        echo -e "\033[1;31m❌ Error al ejecutar entorno local SSL.\033[0m"
        exit 1
    }
    echo -e "\033[1;32m✅ Entorno local SSL finalizado.\033[0m"
    echo ""
fi

echo ""
echo ""
echo ""
sleep 1


echo -e "\033[7;33m----------------------------------------------- GUNICORN ----------------------------------------------\033[0m"
# === CONFIGURACIÓN ===
PUERTOS=(8000 5000 35729)
URL_LOCAL="http://0.0.0.0:5000"
URL_GUNICORN="gunicorn config.wsgi:application --bind 127.0.0.1:8000"
URL_HEROKU="https://apibank2-54644cdf263f.herokuapp.com/"
URL_NJALLA="https://api.coretransapi.com/"
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
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"
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
if [[ "$DO_GUNICORN" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "¿Iniciar Gunicorn, honeypot y livereload?"); then
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

    sleep 1
    firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN" --new-tab "$URL_NJALLA" --new-tab "$URL_HEROKU" &
    FIREFOX_PID=$!

    echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
    echo -e "$LOGO_SEP\n"
    while true; do sleep 1; done
fi

echo ""
echo ""
echo ""
sleep 1
# clear

# echo -e "\033[7;33m----------------------------------------------GUNICORN---------------------------------------------\033[0m"
# # === CONFIGURACIÓN ===
# PUERTOS=(8001 5000 35729)
# URL_LOCAL="http://0.0.0.0:5000"
# URL_GUNICORN="http://0.0.0.0:8011"
# URL_HEROKU="https://apibank2-54644cdf263f.herokuapp.com/"
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
#     export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"
# }
# # === INICIO GUNICORN + HONEYPOT ===
# if [[ "$DO_GUNICORN" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Iniciar Gunicorn, honeypot y livereload"); then
#     echo -e "\033[7;30m🚀 Iniciando Gunicorn, honeypot y livereload...\033[0m"
#     trap limpiar_y_salir SIGINT
#     liberar_puertos
#     iniciar_entorno
#     nohup "$VENV_PATH/bin/gunicorn" config.wsgi:application --workers 3 --bind 127.0.0.1:8001 --keep-alive 2 > "$LOG_DIR/gunicorn_api.log" 2>&1 < /dev/null &
#     nohup python honeypot.py > "$LOG_DIR/honeypot.log" 2>&1 < /dev/null &
#     nohup livereload --host 127.0.0.1 --port 35729 static/ -t templates/ > "$LOG_DIR/livereload.log" 2>&1 < /dev/null &   
#     sleep 1
#     firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN" --new-tab "$URL_HEROKU" &
#     FIREFOX_PID=$!
#     echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
#     echo -e "$LOGO_SEP\n"
#     while true; do sleep 1; done
# fi
# echo ""

# echo ""
# echo ""
# echo ""
# sleep 1
# # clear

# verificar_vpn_segura

# # === ABRIR WEB HEROKU ===
# echo -e "\033[7;33m---------------------------------------------CARGAR WEB--------------------------------------------\033[0m"
# if [[ "$DO_RUN_WEB" == true ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Abrir web Heroku"); then
#     echo -e "\033[7;30m🌐 Abriendo web de Heroku...\033[0m"
#     trap limpiar_y_salir SIGINT
#     liberar_puertos
#     iniciar_entorno
#     firefox --new-window "$URL_HEROKU" &
#     FIREFOX_PID=$!
#     echo -e "\033[7;30m🚧 Web Heroku activa. Ctrl+C para cerrar.\033[0m"
#     echo -e "$LOGO_SEP\n"
#     while true; do sleep 1; done
# fi
# echo ""

echo ""
echo ""
echo ""
sleep 1
# clear

# === FIN: CORREGIDO EL BLOQUE PROBLEMÁTICO ===
URL="$URL_LOCAL"
notify-send "api_bank_h2" "✅ Proyecto iniciado correctamente en:
$URL
$URL_HEROKU
🏁 ¡Todo completado con éxito!"
