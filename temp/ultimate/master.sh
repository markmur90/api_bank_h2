#!/usr/bin/env bash
set -euo pipefail

clear

# Variables de color para salida en consola
COLOR_RESET="\e[0m"
COLOR_SEPARATOR="\e[90m"
COLOR_TITLE="\e[1;93m"
COLOR_COMMAND="\e[1;96m"
COLOR_TEXT="\e[0m"

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

# ============================== #
#       MASTER SCRIPT BANK       #
# ============================== #

ENVIRONMENT=""
POSITIONAL_ARGS=()
for arg in "$@"; do
  case $arg in
    --env=*)
      ENVIRONMENT="${arg#*=}"
      ;;
    *)
      POSITIONAL_ARGS+=("$arg")
      ;;
  esac
done
set -- "${POSITIONAL_ARGS[@]}"

if [[ -z "$ENVIRONMENT" ]]; then
  echo -e "${COLOR_TITLE}❌ Debes especificar el entorno con --env=local|production|heroku${COLOR_RESET}"
  exit 1
fi

BASE_ENV=".env"
SPECIFIC_ENV=".env.${ENVIRONMENT}"

if [[ ! -f "$BASE_ENV" ]]; then
  echo -e "${COLOR_TITLE}❌ No se encontró archivo base ${BASE_ENV}${COLOR_RESET}"
  exit 1
fi

if [[ ! -f "$SPECIFIC_ENV" ]]; then
  echo -e "${COLOR_TITLE}❌ No se encontró archivo específico ${SPECIFIC_ENV}${COLOR_RESET}"
  exit 1
fi

set -a
source "$BASE_ENV"
source "$SPECIFIC_ENV"
set +a

echo -e "${COLOR_TEXT}⚙️ Entorno base y específico (${ENVIRONMENT}) cargados correctamente.${COLOR_RESET}"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
VENV_DIR="${VENV_DIR:-/home/markmur88/Documentos/Entorno/envSIM}"

cd "$BASE_DIR" || exit 1

if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
  echo -e "${COLOR_TITLE}⚠️ No se encontró entorno virtual en $VENV_DIR${COLOR_RESET}"
  exit 1
fi

echo -e "${COLOR_TEXT}🐍 Activando entorno virtual...${COLOR_RESET}"
source "$VENV_DIR/bin/activate"

echo -e "${COLOR_TEXT}🔧 Ejecutando configuración desde config_master.py...${COLOR_RESET}"
python3 -c "from config_master import init_directories; init_directories()"

echo ""
echo -e "${COLOR_SEPARATOR}======================================${COLOR_RESET}"
echo -e "${COLOR_TITLE}✅ Proyecto cargado correctamente${COLOR_RESET}"
echo -e "${COLOR_TEXT}📁 BASE_DIR:         $BASE_DIR"
echo -e "🌍 ENVIRONMENT:      $ENVIRONMENT"
echo -e "📡 INTERFAZ:         $INTERFAZ"
echo -e "🔌 PUERTO:           $PORT"
echo -e "🛡️  TOR_PASS:         ********"
echo -e "🧩 PROJECT_NAME:     $PROJECT_NAME${COLOR_RESET}"
echo -e "${COLOR_SEPARATOR}======================================${COLOR_RESET}"
echo ""

LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="$LOG_DIR/master_run.log"
mkdir -p "$LOG_DIR"
echo "📄 Iniciando nuevo log de ejecución: $(date)" > "$LOG_FILE"

# Inicialización de flags
EJECUTAR_TODO=false
RUN_01_DIAGNOSE=false
RUN_02_PORTS=false
RUN_03_CONTAINERS=false
RUN_04_UPDATE_SYSTEM=false
RUN_05_UFW=false
RUN_06_MACCHANGER=false
RUN_07_TOR=false
RUN_08_CLEAN_ZIP=false
RUN_09_POSTGRES=false
RUN_10_RESET_POSTGRES=false
RUN_11_MIGRATIONS=false
RUN_12_USER=false
RUN_13_LOADDATA=false
RUN_14_PEM=false
RUN_15_ZIP_BACKUP=false
RUN_16_BACKUP_LOCAL=false
RUN_17_SYNC=false
RUN_18_SSL_NGINX=false
RUN_19_GUNICORN=false
RUN_20_DEPLOY_HEROKU=false
RUN_21_DEPLOY_NJALLA=false
RUN_22_TOR_WEB=false
RUN_23_NOTIFY=false
RUN_24_RSYNC_PROJECT=false
RUN_25_UPDATE_DDNS=false
RUN_26_BACKUP_ENCRYPTED=false

if [[ $# -eq 0 || "${1:-}" == "--help" ]]; then
    echo -e "${COLOR_TITLE}Uso:${COLOR_RESET} $0 [opciones] --env=local|production|heroku\n"
    echo -e "${COLOR_TITLE}Opciones disponibles:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}  -a${COLOR_RESET}     Ejecutar todos los scripts"
    echo -e "${COLOR_COMMAND}  -d${COLOR_RESET}     Diagnóstico del entorno"
    echo -e "${COLOR_COMMAND}  -r${COLOR_RESET}     Verificación de puertos"
    echo -e "${COLOR_COMMAND}  -c${COLOR_RESET}     Contenedores activos"
    echo -e "${COLOR_COMMAND}  -u${COLOR_RESET}     Actualización del sistema"
    echo -e "${COLOR_COMMAND}  -f${COLOR_RESET}     Firewall UFW"
    echo -e "${COLOR_COMMAND}  -m${COLOR_RESET}     Cambio MAC"
    echo -e "${COLOR_COMMAND}  -t${COLOR_RESET}     Inicio Tor"
    echo -e "${COLOR_COMMAND}  -k${COLOR_RESET}     Limpieza de backups"
    echo -e "${COLOR_COMMAND}  -p${COLOR_RESET}     Instalación PostgreSQL"
    echo -e "${COLOR_COMMAND}  -x${COLOR_RESET}     Reset de base de datos"
    echo -e "${COLOR_COMMAND}  -g${COLOR_RESET}     Migraciones Django"
    echo -e "${COLOR_COMMAND}  -s${COLOR_RESET}     Creación de superusuario"
    echo -e "${COLOR_COMMAND}  -l${COLOR_RESET}     Carga de fixtures"
    echo -e "${COLOR_COMMAND}  -e${COLOR_RESET}     Generación de claves PEM"
    echo -e "${COLOR_COMMAND}  -z${COLOR_RESET}     Backup comprimido"
    echo -e "${COLOR_COMMAND}  -b${COLOR_RESET}     Backup local"
    echo -e "${COLOR_COMMAND}  -y${COLOR_RESET}     Sincronización multientorno"
    echo -e "${COLOR_COMMAND}  -v${COLOR_RESET}     SSL + Supervisor + Nginx"
    echo -e "${COLOR_COMMAND}  -n${COLOR_RESET}     Ejecución Gunicorn"
    echo -e "${COLOR_COMMAND}  -h${COLOR_RESET}     Deploy Heroku (te preguntará comentario de commit tras confirmar)"
    echo -e "${COLOR_COMMAND}  -j${COLOR_RESET}     Deploy Njalla API bank"
    echo -e "${COLOR_COMMAND}  -o${COLOR_RESET}     Verificación por Tor"
    echo -e "${COLOR_COMMAND}  -q${COLOR_RESET}     Notificación final"
    echo -e "${COLOR_COMMAND}  -i${COLOR_RESET}     Subida de proyectos al VPS"
    echo -e "${COLOR_COMMAND}  -w${COLOR_RESET}     Actualización DDNS Njalla"
    echo -e "${COLOR_COMMAND}  -B${COLOR_RESET}     Backup y Sync Njalla\n"

    echo -e "${COLOR_SEPARATOR}================================================================================${COLOR_RESET}"
    echo -e "${COLOR_TITLE}========================= INICIO ENTORNO LOCAL ================================${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}================================================================================${COLOR_RESET}"
    echo -e "${COLOR_TITLE}Despliegue inicial en Local:${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=local -u -f -p -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}\n"
    echo -e "${COLOR_TITLE}Actualizaciones posteriores en Local:${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Sincronizar solo archivos y código:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=local -i -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Actualizar configuración de firewall, DDNS, etc:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=local -f -w -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Ejecutar backup cifrado y sincronizado:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=local -B -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Ejecutar migraciones, reiniciar servicios, etc:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=local -g -n -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "\n${COLOR_SEPARATOR}--------------------------------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_TITLE}======================== FIN ENTORNO LOCAL / INICIO HEROKU ======================${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}--------------------------------------------------------------------------------${COLOR_RESET}\n"
    echo -e "${COLOR_TITLE}Despliegue inicial en Heroku:${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=heroku -u -p -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}\n"
    echo -e "${COLOR_TITLE}Actualizaciones posteriores en Heroku:${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Sincronizar solo archivos y código:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=heroku -i -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Actualizar configuración de firewall, DDNS, etc:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=heroku -f -w -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Ejecutar backup cifrado y sincronizado:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=heroku -B -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Ejecutar migraciones, reiniciar servicios, etc:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=heroku -g -n -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "\n${COLOR_SEPARATOR}================================================================================${COLOR_RESET}"
    echo -e "${COLOR_TITLE}======================= FIN ENTORNO HEROKU / INICIO PRODUCTION ===================${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}================================================================================${COLOR_RESET}\n"
    echo -e "${COLOR_TITLE}Despliegue inicial a Njalla:${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=production -u -f -p -j -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}\n"
    echo -e "${COLOR_TITLE}Actualizaciones posteriores a Njalla:${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Sincronizar solo archivos y código:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=production -i -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Actualizar configuración de firewall, DDNS, etc:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=production -f -w -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Ejecutar backup cifrado y sincronizado:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=production -B -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    echo -e "${COLOR_TEXT}Ejecutar migraciones, reiniciar servicios, etc:${COLOR_RESET}"
    echo -e "${COLOR_COMMAND}./master.sh --env=production -g -n -q${COLOR_RESET}"
    echo -e "${COLOR_SEPARATOR}============================================${COLOR_RESET}"
    exit 0
fi

while getopts "adrcufmtkpxgslezbyvnhjoqiwB" opt; do
    case "$opt" in
        a) EJECUTAR_TODO=true ;;
        d) RUN_01_DIAGNOSE=true ;;
        r) RUN_02_PORTS=true ;;
        c) RUN_03_CONTAINERS=true ;;
        u) RUN_04_UPDATE_SYSTEM=true ;;
        f) RUN_05_UFW=true ;;
        m) RUN_06_MACCHANGER=true ;;
        t) RUN_07_TOR=true ;;
        k) RUN_08_CLEAN_ZIP=true ;;
        p) RUN_09_POSTGRES=true ;;
        x) RUN_10_RESET_POSTGRES=true ;;
        g) RUN_11_MIGRATIONS=true ;;
        s) RUN_12_USER=true ;;
        l) RUN_13_LOADDATA=true ;;
        e) RUN_14_PEM=true ;;
        z) RUN_15_ZIP_BACKUP=true ;;
        b) RUN_16_BACKUP_LOCAL=true ;;
        y) RUN_17_SYNC=true ;;
        v) RUN_18_SSL_NGINX=true ;;
        n) RUN_19_GUNICORN=true ;;
        h) RUN_20_DEPLOY_HEROKU=true ;;
        j) RUN_21_DEPLOY_NJALLA=true ;;
        o) RUN_22_TOR_WEB=true ;;
        q) RUN_23_NOTIFY=true ;;
        i) RUN_24_RSYNC_PROJECT=true ;;
        w) RUN_25_UPDATE_DDNS=true ;;
        B) RUN_26_BACKUP_ENCRYPTED=true ;;
        \?) echo -e "${COLOR_TITLE}❌ Opción inválida: -$OPTARG${COLOR_RESET}" >&2; exit 1 ;;
    esac
done

if [[ "$EJECUTAR_TODO" == true ]]; then
    RUN_01_DIAGNOSE=true
    RUN_02_PORTS=true
    RUN_03_CONTAINERS=true
    RUN_04_UPDATE_SYSTEM=true
    RUN_05_UFW=true
    RUN_06_MACCHANGER=true
    RUN_07_TOR=true
    RUN_08_CLEAN_ZIP=true
    RUN_09_POSTGRES=true
    RUN_10_RESET_POSTGRES=true
    RUN_11_MIGRATIONS=true
    RUN_12_USER=true
    RUN_13_LOADDATA=true
    RUN_14_PEM=true
    RUN_15_ZIP_BACKUP=true
    RUN_16_BACKUP_LOCAL=true
    RUN_17_SYNC=true
    RUN_18_SSL_NGINX=true
    RUN_19_GUNICORN=true
    RUN_20_DEPLOY_HEROKU=true
    RUN_21_DEPLOY_NJALLA=true
    RUN_22_TOR_WEB=true
    RUN_23_NOTIFY=true
    RUN_24_RSYNC_PROJECT=true
    RUN_25_UPDATE_DDNS=true
    RUN_26_BACKUP_ENCRYPTED=true
fi

# Aquí puedes seguir con el resto de ejecución llamando a scripts, etc...



LISTA_PENDIENTES=()
LISTA_NO_EJECUTADOS=()

[[ "$RUN_01_DIAGNOSE" == true ]] && LISTA_PENDIENTES+=("-d Diagnóstico del entorno") || LISTA_NO_EJECUTADOS+=("-d Diagnóstico del entorno")
[[ "$RUN_02_PORTS" == true ]] && LISTA_PENDIENTES+=("-r Verificación de puertos") || LISTA_NO_EJECUTADOS+=("-r Verificación de puertos")
[[ "$RUN_03_CONTAINERS" == true ]] && LISTA_PENDIENTES+=("-c Contenedores activos") || LISTA_NO_EJECUTADOS+=("-c Contenedores activos")
[[ "$RUN_04_UPDATE_SYSTEM" == true ]] && LISTA_PENDIENTES+=("-u Actualización del sistema") || LISTA_NO_EJECUTADOS+=("-u Actualización del sistema")
[[ "$RUN_05_UFW" == true ]] && LISTA_PENDIENTES+=("-f Firewall UFW") || LISTA_NO_EJECUTADOS+=("-f Firewall UFW")
[[ "$RUN_06_MACCHANGER" == true ]] && LISTA_PENDIENTES+=("-m Cambio MAC") || LISTA_NO_EJECUTADOS+=("-m Cambio MAC")
[[ "$RUN_07_TOR" == true ]] && LISTA_PENDIENTES+=("-t Inicio Tor") || LISTA_NO_EJECUTADOS+=("-t Inicio Tor")
[[ "$RUN_08_CLEAN_ZIP" == true ]] && LISTA_PENDIENTES+=("-k Limpieza de backups") || LISTA_NO_EJECUTADOS+=("-k Limpieza de backups")
[[ "$RUN_09_POSTGRES" == true ]] && LISTA_PENDIENTES+=("-p Instalación PostgreSQL") || LISTA_NO_EJECUTADOS+=("-p Instalación PostgreSQL")
[[ "$RUN_10_RESET_POSTGRES" == true ]] && LISTA_PENDIENTES+=("-x Reset de base de datos") || LISTA_NO_EJECUTADOS+=("-x Reset de base de datos")
[[ "$RUN_11_MIGRATIONS" == true ]] && LISTA_PENDIENTES+=("-g Migraciones Django") || LISTA_NO_EJECUTADOS+=("-g Migraciones Django")
[[ "$RUN_12_USER" == true ]] && LISTA_PENDIENTES+=("-s Creación de superusuario") || LISTA_NO_EJECUTADOS+=("-s Creación de superusuario")
[[ "$RUN_13_LOADDATA" == true ]] && LISTA_PENDIENTES+=("-l Carga de fixtures") || LISTA_NO_EJECUTADOS+=("-l Carga de fixtures")
[[ "$RUN_14_PEM" == true ]] && LISTA_PENDIENTES+=("-e Generación de claves PEM") || LISTA_NO_EJECUTADOS+=("-e Generación de claves PEM")
[[ "$RUN_15_ZIP_BACKUP" == true ]] && LISTA_PENDIENTES+=("-z Backup comprimido") || LISTA_NO_EJECUTADOS+=("-z Backup comprimido")
[[ "$RUN_16_BACKUP_LOCAL" == true ]] && LISTA_PENDIENTES+=("-b Backup local") || LISTA_NO_EJECUTADOS+=("-b Backup local")
[[ "$RUN_17_SYNC" == true ]] && LISTA_PENDIENTES+=("-y Sincronización multientorno") || LISTA_NO_EJECUTADOS+=("-y Sincronización multientorno")
[[ "$RUN_18_SSL_NGINX" == true ]] && LISTA_PENDIENTES+=("-v SSL + Supervisor + Nginx") || LISTA_NO_EJECUTADOS+=("-v SSL + Supervisor + Nginx")
[[ "$RUN_19_GUNICORN" == true ]] && LISTA_PENDIENTES+=("-n Ejecución Gunicorn") || LISTA_NO_EJECUTADOS+=("-n Ejecución Gunicorn")
[[ "$RUN_20_DEPLOY_HEROKU" == true ]] && LISTA_PENDIENTES+=("-h Deploy Heroku") || LISTA_NO_EJECUTADOS+=("-h Deploy Heroku")
[[ "$RUN_21_DEPLOY_NJALLA" == true ]] && LISTA_PENDIENTES+=("-j Deploy Njalla API bank") || LISTA_NO_EJECUTADOS+=("-j Deploy Njalla API bank")
[[ "$RUN_22_TOR_WEB" == true ]] && LISTA_PENDIENTES+=("-o Verificación por Tor") || LISTA_NO_EJECUTADOS+=("-o Verificación por Tor")
[[ "$RUN_23_NOTIFY" == true ]] && LISTA_PENDIENTES+=("-q Notificación final") || LISTA_NO_EJECUTADOS+=("-q Notificación final")
[[ "$RUN_24_RSYNC_PROJECT" == true ]] && LISTA_PENDIENTES+=("-i Subida de proyectos al VPS") || LISTA_NO_EJECUTADOS+=("-i Subida de proyectos al VPS")
[[ "$RUN_25_UPDATE_DDNS" == true ]] && LISTA_PENDIENTES+=("-w Actualización DDNS Njalla") || LISTA_NO_EJECUTADOS+=("-w Actualización DDNS Njalla")
[[ "$RUN_26_BACKUP_ENCRYPTED" == true ]] && LISTA_PENDIENTES+=("-B Backup y Sync Njalla") || LISTA_NO_EJECUTADOS+=("-B Backup y Sync Njalla")

echo -e "\n\033[1;36m📦 Vas a ejecutar los siguientes pasos:\033[0m"
for paso in "${LISTA_PENDIENTES[@]}"; do
    echo -e "  • $paso"
done
echo ""

echo -e "\n\033[1;31m❌ No se ejecutarán los siguientes pasos:\033[0m"
for paso in "${LISTA_NO_EJECUTADOS[@]}"; do
    echo -e "  • $paso"
done
echo ""

read -rp $'\033[1;33m¿Deseas continuar? [Y/n]: \033[0m' confirmacion
confirmacion=${confirmacion,,} # a minúscula
if [[ "$confirmacion" =~ ^(n|no)$ ]]; then
    echo -e "\n\033[1;31m❌ Ejecución cancelada por el usuario.\033[0m"
    exit 1
fi

# Preguntar commit si se ejecuta deploy Heroku
if [[ "$RUN_20_DEPLOY_HEROKU" == true ]]; then
  echo -n "✏️ Introduce el comentario para el commit de deploy Heroku: "
  read -r COMENTARIO_COMMIT
  if [[ -z "$COMENTARIO_COMMIT" ]]; then
    echo "❌ El comentario no puede estar vacío. Abortando."
    exit 1
  fi
  export COMENTARIO_COMMIT
fi

RESUMEN_SCRIPTS=()
TIEMPO_TOTAL_INICIO=$(date +%s)

ejecutar_script() {
    local script_name="$1"
    local description="$2"
    local inicio=$(date +%s)
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ -f "$SCRIPTS_DIR/$script_name" ]]; then
        printf "[#=============================================================================================================================================]\n\n\n" >> "$LOG_FILE"
        echo -e "\033[1;34m➡️ [$timestamp] Ejecutando: $description ($script_name)\033[0m"
        local salida
        salida=$(bash "$SCRIPTS_DIR/$script_name" 2>&1)
        echo "[$timestamp] INFO Ejecutado: $description ($script_name)" >> "$LOG_FILE"
        echo "$salida" >> "$LOG_FILE"
        local fin=$(date +%s)
        local duracion=$((fin - inicio))
        RESUMEN_SCRIPTS+=("✅ $description ($script_name) — ${duracion}s")
        echo -e "\033[1;32m✅ Completado: $description [${duracion}s]\033[0m\n"
    else
        RESUMEN_SCRIPTS+=("❌ Script no encontrado: $description ($script_name)")
        echo -e "\033[1;31m❌ Script no encontrado: $SCRIPTS_DIR/$script_name\033[0m" | tee -a "$LOG_FILE"
    fi
}

[[ "$RUN_01_DIAGNOSE" == true ]] && ejecutar_script "01_diagnose.sh" "Diagnóstico del entorno"
[[ "$RUN_02_PORTS" == true ]] && ejecutar_script "02_ports.sh" "Verificación de puertos"
[[ "$RUN_03_CONTAINERS" == true ]] && ejecutar_script "03_containers.sh" "Contenedores activos"
[[ "$RUN_04_UPDATE_SYSTEM" == true ]] && ejecutar_script "04_update_system.sh" "Actualización del sistema"
[[ "$RUN_05_UFW" == true ]] && ejecutar_script "05_ufw.sh" "Firewall UFW"
[[ "$RUN_06_MACCHANGER" == true ]] && ejecutar_script "06_macchanger.sh" "Cambio MAC"
[[ "$RUN_07_TOR" == true ]] && ejecutar_script "07_tor.sh" "Inicio Tor"
[[ "$RUN_08_CLEAN_ZIP" == true ]] && ejecutar_script "08_clean_zip.sh" "Limpieza de backups"
[[ "$RUN_09_POSTGRES" == true ]] && ejecutar_script "09_postgres.sh" "Instalación PostgreSQL"
[[ "$RUN_10_RESET_POSTGRES" == true ]] && ejecutar_script "10_reset_postgres.sh" "Reset de base de datos"
[[ "$RUN_11_MIGRATIONS" == true ]] && ejecutar_script "11_migrations.sh" "Migraciones Django"
[[ "$RUN_12_USER" == true ]] && ejecutar_script "12_user.sh" "Creación de superusuario"
[[ "$RUN_13_LOADDATA" == true ]] && ejecutar_script "13_loaddata.sh" "Carga de fixtures"
[[ "$RUN_14_PEM" == true ]] && ejecutar_script "14_pem.sh" "Generación de claves PEM"
[[ "$RUN_15_ZIP_BACKUP" == true ]] && ejecutar_script "15_zip_backup.sh" "Backup comprimido"
[[ "$RUN_16_BACKUP_LOCAL" == true ]] && ejecutar_script "16_backup_local.sh" "Backup local"
[[ "$RUN_17_SYNC" == true ]] && ejecutar_script "17_sync.sh" "Sincronización multientorno"
[[ "$RUN_18_SSL_NGINX" == true ]] && ejecutar_script "18_ssl_nginx.sh" "SSL + Supervisor + Nginx"
[[ "$RUN_19_GUNICORN" == true ]] && ejecutar_script "19_gunicorn.sh" "Ejecución Gunicorn"
[[ "$RUN_20_DEPLOY_HEROKU" == true ]] && ejecutar_script "20_deploy_heroku.sh" "Deploy Heroku"
[[ "$RUN_21_DEPLOY_NJALLA" == true ]] && ejecutar_script "21_deploy_njalla.sh" "Deploy Njalla API bank"
[[ "$RUN_22_TOR_WEB" == true ]] && ejecutar_script "22_tor_web.sh" "Verificación por Tor"
[[ "$RUN_23_NOTIFY" == true ]] && ejecutar_script "23_notify.sh" "Notificación final"
[[ "$RUN_24_RSYNC_PROJECT" == true ]] && ejecutar_script "24_rsync_project.sh" "Subida de proyectos al VPS"
[[ "$RUN_25_UPDATE_DDNS" == true ]] && ejecutar_script "25_update_ddns_njalla.sh" "Actualización DDNS Njalla"
[[ "$RUN_25_UPDATE_DDNS" == true ]] && ejecutar_script "26_backup_sync_encrypt.sh" "Backup y Sync Njalla"

mostrar_resumen_final() {
    local TIEMPO_TOTAL_FIN=$(date +%s)
    local DURACION_TOTAL=$((TIEMPO_TOTAL_FIN - TIEMPO_TOTAL_INICIO))

    echo -e "\n\033[1;36m📋 RESUMEN DE EJECUCIÓN:\033[0m"
    for entrada in "${RESUMEN_SCRIPTS[@]}"; do
        echo -e "  $entrada"
    done

    echo -e "\n\033[1;35m⏱️ Tiempo total: ${DURACION_TOTAL}s\033[0m"
    echo -e "\033[1;36m🗂️ Log completo disponible en: $LOG_FILE\033[0m"
    echo ""
}

mostrar_resumen_final
