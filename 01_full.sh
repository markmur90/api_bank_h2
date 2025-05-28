#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_DEPLOY="./scripts/logs/01_full_deploy/full_deploy.log"

clear
# === CONTROLES DE PAUSA Y LIMPIEZA DE PANTALLA ===
DO_CLEAR=false
TIME_SLEEP=0

pausa_y_limpiar() {
    sleep "$TIME_SLEEP"
    if [[ "$DO_CLEAR" == true ]]; then
        clear
    fi
}

echo "🔐 Solicitando acceso sudo..."
if sudo -v; then
    while true; do
        sudo -v
        sleep 60
    done &

    SUDO_KEEP_ALIVE_PID=$!
    trap 'kill $SUDO_KEEP_ALIVE_PID; echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE_SCRIPT"; exit 1' ERR
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
NJALLA_ROOT="$HOME/Documentos/GitHub/coretransapi"
VENV_PATH="$HOME/Documentos/Entorno/envAPP"
INTERFAZ="wlan0"
LOG_DIR="$PROJECT_ROOT/scripts/logs/01_full_deploy"
LOG_FILE_SCRIPT="$LOG_DIR/full_deploy.log"
STARTUP_LOG="$LOG_DIR/startup.log"



# === FLAGS DE CONTROL DE BLOQUES ===
DRY_RUN=false
PROMPT_MODE=false
DEBUG_MODE=true       # 00
DO_SYS=false
DO_ZIP_SQL=false
DO_PORTS=false
DO_DOCKER=false
DO_MAC=false
DO_JSON_LOCAL=false
DO_UFW=false
DO_PGSQL=false
DO_MIG=false
DO_RUN_LOCAL=false
DO_USER=false
DO_PEM=false
DO_VERIF_TRANSF=false
DO_SYNC_LOCAL=false
DO_VARHER=false
DO_HEROKU=false
DO_SYNC_REMOTE_DB=false
DO_DEPLOY_VPS=false
DO_CLEAN=false
DO_GUNICORN=false
DO_LOCAL_SSL=false
DO_CERT=false

if [[ "$@" =~ -[Y-Zy-z] ]]; then
    PROMPT_MODE=false
fi

# === PARÁMETRO DE ENTORNO --env ===
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == --env=* ]]; then
    ENTORNO="${arg#*=}"
    echo -e "🌐 Entorno seleccionado: $ENTORNO"
    export DJANGO_ENV="$ENTORNO"
    continue  # omitimos agregar este argumento
  fi
  ARGS+=("$arg")
done

# Reasignamos los argumentos sin el --env
set -- "${ARGS[@]}"


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
    echo -e "\n\033[1;36mUSO:\033[0m"
    echo -e "  bash ./01_full.sh [opciones]\n"

    echo -e "\033[1;33mOPCIONES DISPONIBLES:\033[0m"
    echo -e "  \033[1;33m-a\033[0m, \033[1;33m--all\033[0m               Ejecutar sin confirmaciones interactivas"
    echo -e "  \033[1;33m-s\033[0m, \033[1;33m--step\033[0m              Activar modo paso a paso (pregunta todo)"
    echo -e "  \033[1;33m-d\033[0m, \033[1;33m--debug\033[0m             Mostrar diagnóstico y variables actuales"
    echo -e "  \033[1;33m-h\033[0m, \033[1;33m--help\033[0m              Mostrar esta ayuda y salir"

    echo -e "\n\033[1;33mTAREAS DE DESARROLLO LOCAL:\033[0m"
    echo -e "  \033[1;33m-L\033[0m, \033[1;33m--do-local\033[0m          Descargar archivos locales .json/.env"
    echo -e "  \033[1;33m-l\033[0m, \033[1;33m--do-load-local\033[0m     Subir archivos locales .json/.env"
    echo -e "  \033[1;33m-Q\033[0m, \033[1;33m--do-pgsql\033[0m          Configurar PostgreSQL local"
    echo -e "  \033[1;33m-I\033[0m, \033[1;33m--do-migra\033[0m          Aplicar migraciones Django"
    echo -e "  \033[1;33m-U\033[0m, \033[1;33m--do-create-user\033[0m    Crear usuario del sistema"

    echo -e "\n\033[1;33mBACKUPS:\033[0m"
    echo -e "  \033[1;33m-C\033[0m, \033[1;33m--do-clean\033[0m          Limpiar respaldos antiguos"
    echo -e "  \033[1;33m-Z\033[0m, \033[1;33m--do-zip\033[0m            Generar backups ZIP + SQL"

    echo -e "\n\033[1;33mDEPLOY:\033[0m"
    echo -e "  \033[1;33m-S\033[0m, \033[1;33m--do-sync\033[0m           Sincronizar archivos locales"
    echo -e "  \033[1;33m-B\033[0m, \033[1;33m--do-bdd\033[0m            Sincronizar BDD remota"
    echo -e "  \033[1;33m-H\033[0m, \033[1;33m--do-heroku\033[0m         Desplegar a Heroku"
    echo -e "  \033[1;33m-u\033[0m, \033[1;33m--do-varher\033[0m         Configurar variables Heroku"
    echo -e "  \033[1;33m-v\033[0m, \033[1;33m--do-vps\033[0m            Desplegar a VPS (Njalla)"

    echo -e "\n\033[1;33mENTORNO Y CONFIGURACIÓN:\033[0m"
    echo -e "  \033[1;33m-Y\033[0m, \033[1;33m--do-sys\033[0m            Actualizar sistema y dependencias"
    echo -e "  \033[1;33m-P\033[0m, \033[1;33m--do-ports\033[0m          Cerrar puertos abiertos conflictivos"
    echo -e "  \033[1;33m-D\033[0m, \033[1;33m--do-docker\033[0m         Cerrar contenedores abiertos conflictivos"
    echo -e "  \033[1;33m-M\033[0m, \033[1;33m--do-mac\033[0m            Cambiar MAC aleatoria"
    echo -e "  \033[1;33m-x\033[0m, \033[1;33m--do-ufw\033[0m            Configurar firewall UFW"
    echo -e "  \033[1;33m-p\033[0m, \033[1;33m--do-pem\033[0m            Generar claves PEM locales"
    echo -e "  \033[1;33m-E\033[0m, \033[1;33m--do-cert\033[0m           Generar certificados SSL locales"

    echo -e "\n\033[1;33mEJECUCIÓN Y TESTING:\033[0m"
    echo -e "  \033[1;33m-r\033[0m, \033[1;33m--do-local-ssl\033[0m      Ejecutar entorno local con SSL (Gunicorn + Nginx 8443) 🚀"
    echo -e "  \033[1;33m-G\033[0m, \033[1;33m--do-gunicorn\033[0m       Ejecutar Gunicorn"
    echo -e "  \033[1;33m-V\033[0m, \033[1;33m--do-verif-trans\033[0m    Verificar transferencias SEPA"
}



# === PARSEO DE ARGUMENTOS ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)             PROMPT_MODE=false ;;
        -s|--step)            PROMPT_MODE=true ;;
        -W|--dry-run)         DRY_RUN=true ;;
        -B|--do-bdd)          DO_SYNC_REMOTE_DB=true ;;
        -H|--do-heroku)       DO_HEROKU=true ;;
        -u|--do-varher)       DO_VARHER=true ;;
        -G|--do-gunicorn)     DO_GUNICORN=true ;;
        -C|--do-clean)        DO_CLEAN=true ;;
        -L|--do-local)        DO_JSON_LOCAL=true ;;
        -S|--do-sync)         DO_SYNC_LOCAL=true ;;
        -D|--do-docker)       DO_DOCKER=true ;;
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
        -V|--do-verif-trans)  DO_VERIF_TRANSF=true ;;
        -v|--do-vps)          DO_DEPLOY_VPS=true ;;
        -d|--debug)           DEBUG_MODE=true ;;
        -r|--do-local-ssl)    DO_LOCAL_SSL=true ;;  # 🚀 NUEVO FLAG
        -E|--do-cert)         DO_CERT=true ;;     # 🚀 NUEVO FLAG
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
    local respuesta
    read -rp "🔷 ¿Confirmas: $1? (s/S + Enter para sí, Enter solo también cuenta): " respuesta
    case "${respuesta:-s}" in
        [sS]|"") return 0 ;;
        *)       return 1 ;;
    esac
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
    printf "%-20s =\t%s\n" "PRIVATE_KEY_PATH"    "$PROJECT_ROOT/schemas/keys/private_key.pem"
    printf "%-20s =\t%s\n" "SERVERS_DIR"         "$PROJECT_ROOT/servers"
    printf "%-20s =\t%s\n" "CACHE_DIR"           "$PROJECT_ROOT/tmp"
    printf "%-20s =\t%s\n" "PROJECT_ROOT"        "$PROJECT_ROOT"
    printf "%-20s =\t%s\n" "LOG_DIR"             "$LOG_DIR"
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
    if [[ "$DRY_RUN" == true ]]; then
        echo "🧪 DRY-RUN: Ejecutaría → $accion"
    else
                eval "$accion"
    fi
    fi
}


# === LLAMAR AL DIAGNÓSTICO TEMPRANO ===
# diagnostico_entorno

echo -e "\n\n"
pausa_y_limpiar


# === 01 ===
echo -e "\033[7;33m------------------------------------------------SISTEMA------------------------------------------------\033[0m"
echo -e "\n\n\n------------------------------------SISTEMA----------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_SYS" "Actualizar sistema" "bash $SCRIPTS_DIR/00_01_sistema.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 02 ===
echo -e "\033[7;33m----------------------------------------------------ZIP------------------------------------------------\033[0m"
echo "--------------------------------------ZIP------------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_ZIP_SQL" "Crear zip y sql" "bash $SCRIPTS_DIR/00_02_zip_backup.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 03 ===
echo -e "\033[7;33m------------------------------------------------PUERTOS------------------------------------------------\033[0m"
echo "------------------------------------PUERTOS----------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_PORTS" "Cerrar puertos" "bash $SCRIPTS_DIR/00_03_puertos.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 04 ===
echo -e "\033[7;33m----------------------------------------------CONTENEDORES---------------------------------------------\033[0m"
echo "----------------------------------CONTENEDORES-------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_DOCKER" "Cerrar contenedores" "bash $SCRIPTS_DIR/00_04_container.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 05 ===
echo -e "\033[7;33m-----------------------------------------------CAMBIO MAC----------------------------------------------\033[0m" 
echo "-----------------------------------CAMBIO MAC--------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_MAC" "Cambiar MAC" "bash $SCRIPTS_DIR/00_05_mac.sh"
echo -e "\n\n"
pausa_y_limpiar
verificar_vpn_segura
# === 06 ===
echo -e "\033[7;33m--------------------------------------------------UFW--------------------------------------------------\033[0m" 
echo "--------------------------------------UFW------------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_UFW" "Configurar UFW" "bash $SCRIPTS_DIR/00_06_ufw.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 07 ===
echo -e "\033[7;33m------------------------------------------------POSTGRES-----------------------------------------------\033[0m" 
echo "-----------------------------------POSTGRES----------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_PGSQL" "Configurar PostgreSQL" "bash $SCRIPTS_DIR/00_07_postgres.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 08 ===
echo -e "\033[7;33m----------------------------------------------MIGRACIONES----------------------------------------------\033[0m" 
echo "---------------------------------MIGRACIONES---------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_MIG" "Ejecutar migraciones" "bash $SCRIPTS_DIR/00_08_migraciones.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 09 ===
echo -e "\033[7;33m----------------------------------------------CARGAR LOCAL---------------------------------------------\033[0m" 
echo "---------------------------------CARGAR LOCAL--------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_RUN_LOCAL" "Subir bdd_local" "bash $SCRIPTS_DIR/00_09_cargar_json.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 10 ===
echo -e "\033[7;33m------------------------------------------------USUARIO------------------------------------------------\033[0m" 
echo "-----------------------------------USUARIO-----------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_USER" "Crear Super Usuario" "bash $SCRIPTS_DIR/00_10_usuario.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 11 ===
echo -e "\033[7;33m--------------------------------------------RESPALDOS LOCAL--------------------------------------------\033[0m" 
echo "-------------------------------RESPALDOS LOCAL-------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_JSON_LOCAL" "Crear respaldo JSON local" "bash $SCRIPTS_DIR/00_11_hacer_json.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 12 ===
echo -e "\033[7;33m------------------------------------------------PEM JWKS-----------------------------------------------\033[0m" 
echo "---------------------------------PEM JWKS------------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_PEM" "Generar PEM JWKS" "bash $SCRIPTS_DIR/00_12_pem.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 13 ===
echo -e "\033[7;33m----------------------------------------VERIFICAR TRANSFERENCIAS---------------------------------------\033[0m" 
echo "-----------------------VERIFICAR TRANSFERENCIAS------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_VERIF_TRANSF" "Verificar Transferencias" "bash $SCRIPTS_DIR/00_13_verificar_transferencias.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 14 ===
echo -e "\033[7;33m----------------------------------------SINCRONIZACION COMPLETA----------------------------------------\033[0m" 
echo "------------------------SINCRONIZACION COMPLETA------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_SYNC_LOCAL" "Sincronizar Archivos Locales" "bash $SCRIPTS_DIR/00_14_sincronizacion_archivos.sh"
echo -e "\n\n"
pausa_y_limpiar

verificar_vpn_segura
verificar_configuracion_segura
rotar_logs_si_grandes

# === 15 ===
echo -e "\033[7;33m-------------------------------------------VARIABLES A HEROKU------------------------------------------\033[0m" 
echo "---------------------------VARIABLES A HEROKU--------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_VARHER" "Subir variables a Heroku" "bash $SCRIPTS_DIR/00_15_variables_heroku.sh"
echo ""
echo -e "\n\n"
pausa_y_limpiar

# === 16 ===
echo -e "\033[7;33m---------------------------------------------SUBIR A HEROKU--------------------------------------------\033[0m" 
echo "-----------------------------SUBIR A HEROKU----------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_HEROKU" "Subir el proyecto a la web" "bash $SCRIPTS_DIR/00_16_subir_heroku.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 17 ===
echo -e "\033[7;33m-----------------------------------------SINCRONIZACION BDD WEB----------------------------------------\033[0m" 
echo "-------------------------SINCRONIZACION BDD WEB------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_SYNC_REMOTE_DB" "Sincronizar BDD Remota" "bash $SCRIPTS_DIR/00_17_sincronizar_bdd.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 18 ===
echo -e "\033[7;33m-----------------------------------DEPLOY REMOTO A VPS - CORETRANSAPI----------------------------------\033[0m" 
echo "----------------------------------VPS----------------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_DEPLOY_VPS" "Desplegar en VPS" "bash $SCRIPTS_DIR/00_18_deploy_njalla.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 19 ===
echo -e "\033[7;33m-------------------------------------------BORRANDO ZIP Y SQL------------------------------------------\033[0m" 
echo "---------------------------------CLEAN---------------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_CLEAN" "Limpiar respaldos" "bash $SCRIPTS_DIR/00_19_borrar_zip_sql.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 20 ===
echo -e "\033[7;33m------------------------------------------------- SSL -------------------------------------------------\033[0m" 
echo "----------------------------------SSL----------------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_CERT" "Generar Certificado" "bash $SCRIPTS_DIR/00_20_ssl.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 21 ===
echo -e "\033[7;33m-----------------------------------------ENTORNO LOCAL CON SSL-----------------------------------------\033[0m" 
echo "------------------------------LOCAL + SSL------------------------------" >> "$LOG_DEPLOY"
if [[ "$DO_LOCAL_SSL" == true && "$DO_GUNICORN" == true ]]; then
    echo -e "\033[1;31m❌ No puedes ejecutar DO_LOCAL_SSL y DO_GUNICORN al mismo tiempo.\033[0m"
    exit 1
fi
ejecutar_si_activo "DO_LOCAL_SSL" "Iniciar entorno local con Gunicorn + SSL" "bash $SCRIPTS_DIR/00_21_local_ssl.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 22 ===
echo -e "\033[7;33m----------------------------------------------- GUNICORN ----------------------------------------------\033[0m" 
echo "--------------------------------GUNICORN------------------------------" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_GUNICORN" "Iniciar Gunicorn, honeypot y livereload" "bash $SCRIPTS_DIR/00_22_gunicorn.sh"
echo -e "\n\n"
pausa_y_limpiar

# === 23 ===
echo -e "\033[7;34m-------------------------------------------- DEPLOY COMPLETO ------------------------------------------\033[0m" 
echo -e "----------------------------DEPLOY COMPLETO----------------------------\n\n\n" >> "$LOG_DEPLOY"
URL_LOCAL="http://0.0.0.0:5000"
URL_GUNICORN="gunicorn config.wsgi:application --bind 127.0.0.1:8000"
URL_HEROKU="https://apibank2-54644cdf263f.herokuapp.com/"
URL_NJALLA="https://apih.coretransapi.com/"

# === FIN: CORREGIDO EL BLOQUE PROBLEMÁTICO ===
URL="$URL_LOCAL"
notify-send "api_bank_h2" "✅ Proyecto iniciado correctamente en:
$URL
$URL_HEROKU
🏁 ¡Todo completado con éxito!"


# === RESUMEN FINAL DEL PROCESO ===
echo -e "\n\n\033[1;36m📋 RESUMEN FINAL:\033[0m"
echo "🔹 Log principal de ejecución: $LOG_FILE_SCRIPT"
echo "🔹 Log de despliegue resumido: $LOG_DEPLOY"
echo "🔹 Estado: $(if [[ $? -eq 0 ]]; then echo '✅ Éxito'; else echo '❌ Con errores'; fi)"
