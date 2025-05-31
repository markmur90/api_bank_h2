#!/usr/bin/env bash


clear
# === CONTROLES DE PAUSA Y LIMPIEZA DE PANTALLA ===
DO_CLEAR=false
TIME_SLEEP=1

pausa_y_limpiar() {
    sleep "$TIME_SLEEP"
    if [[ "$DO_CLEAR" == true ]]; then
        clear
    fi
}



cat <<'EOF'
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║                    SCRIPT MAESTRO DE DESPLIEGUE - api_bank_h2               ║
# ║  Ejecuta `deploy_menu` para selección interactiva con FZF                   ║
# ║  Ejecuta `d_help` para ver ejemplos combinados y sus parámetros             ║
# ║                                                                             ║
# ║  === ALIAS DISPONIBLES (desde aliases_deploy.sh) ===                        ║
# ║  🖥️  Local:                                                                 ║
# ║    - api         → Activa entorno + entra al proyecto principal             ║
# ║    - d_local     → Despliegue local con flags de prueba                     ║
# ║    - d_heroku    → Despliegue heroku                                        ║
# ║    - d_env       → Activa solo el entorno virtual                           ║
# ║    - d_mig       → makemigrations + migrate + collectstatic                 ║
# ║                                                                             ║
# ║  🌐 VPS Njalla:                                                             ║
# ║    - vps_login   → Conexión SSH al servidor                                 ║
# ║    - vps_reload  → Reinicia Gunicorn y recarga Nginx                        ║
# ║    - vps_logs    → Log live del servicio Gunicorn                           ║
# ║    - vps_status  → Verifica estado actual de Gunicorn                       ║
# ║    - vps_sync    → Sincroniza código local al servidor (rsync)              ║
# ║    - vps_cert    → Testea renovación automática de Certbot                  ║
# ║    - vps_ping    → Test de conexión TCP hacia el VPS                        ║
# ║                                                                             ║
# ║  Usa `source scripts/aliases_deploy.sh` para habilitarlos en la terminal.   ║
# ║  Autor: markmur88                                                           ║
# ╚═════════════════════════════════════════════════════════════════════════════╝
EOF
pausa_y_limpiar


set -euo pipefail

centrar_texto() {
  local texto="$1"
  local ancho=43
  local relleno_char="-"
  local largo_texto=${#texto}
  local relleno_total=$((ancho - largo_texto - 2))
  local relleno_izq=$((relleno_total / 2))
  local relleno_der=$((relleno_total - relleno_izq))
  printf "
%s %s %s
" \
    "$(printf "%${relleno_izq}s" | tr ' ' "$relleno_char")" \
    "$texto" \
    "$(printf "%${relleno_der}s" | tr ' ' "$relleno_char")"
}

centrar_texto_coloreado() {
  local texto="$1"
  local ancho=78
  local relleno_char="-"
  local texto_sin_color="$(echo -e "$texto" | sed 's/\x1b\[[0-9;]*m//g')"
  local largo_texto=${#texto_sin_color}
  local relleno_total=$((ancho - largo_texto - 2))
  local relleno_izq=$((relleno_total / 2))
  local relleno_der=$((relleno_total - relleno_izq))
  printf "%s %s %s\n" \
    "$(printf "%${relleno_izq}s" | tr ' ' "$relleno_char")" \
    "$texto" \
    "$(printf "%${relleno_der}s" | tr ' ' "$relleno_char")"
}

SCRIPT_NAME="$(basename "$0")"
LOG_DEPLOY="./scripts/logs/01_full_deploy/full_deploy.log"

# clear


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

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║                    SCRIPT MAESTRO DE DESPLIEGUE - api_bank_h2               ║
# ║  Automatización total: setup, backups, deploy, limpieza y seguridad         ║
# ║  Soporte para 30 combinaciones de despliegue con alias `d_*`                ║
# ║  Ejecuta `deploy_menu` para selección interactiva con FZF                   ║
# ║  Ejecuta `d_help` para ver ejemplos combinados y sus parámetros             ║
# ║                                                                             ║
# ║  === ALIAS DISPONIBLES (desde aliases_deploy.sh) ===                       ║
# ║                                                                             ║
# ║  🖥️  Local:                                                                 ║
# ║    - api         → Activa entorno + entra al proyecto principal            ║
# ║    - d_local     → Despliegue local con flags de prueba                    ║
# ║    - d_env       → Activa solo el entorno virtual                          ║
# ║    - d_mig       → makemigrations + migrate + collectstatic                ║
# ║                                                                             ║
# ║  🌐 VPS Njalla:                                                             ║
# ║    - vps_login   → Conexión SSH al servidor                                ║
# ║    - vps_reload  → Reinicia Gunicorn y recarga Nginx                       ║
# ║    - vps_logs    → Log live del servicio Gunicorn                          ║
# ║    - vps_status  → Verifica estado actual de Gunicorn                      ║
# ║    - vps_sync    → Sincroniza código local al servidor (rsync)            ║
# ║    - vps_cert    → Testea renovación automática de Certbot                ║
# ║    - vps_ping    → Test de conexión TCP hacia el VPS                       ║
# ║                                                                             ║
# ║  Usa `source scripts/aliases_deploy.sh` para habilitarlos en la terminal. ║

# ║  Autor: markmur88                                                           ║
# ╚═════════════════════════════════════════════════════════════════════════════╝

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

# === DETENER SI NO HAY ARGUMENTOS Y SOLO MOSTRAR ENCABEZADO ===
# if [[ $# -eq 0 ]]; then
#     echo ""
#     cat <<'EOF'
# # ╔═════════════════════════════════════════════════════════════════════════════╗
# # ║                    SCRIPT MAESTRO DE DESPLIEGUE - api_bank_h2               ║
# # ║  Automatización total: setup, backups, deploy, limpieza y seguridad         ║
# # ║  Soporte para 30 combinaciones de despliegue con alias `d_*`                ║
# # ║  Ejecuta `deploy_menu` para selección interactiva con FZF                   ║
# # ║  Ejecuta `d_help` para ver ejemplos combinados y sus parámetros             ║
# # ╚═════════════════════════════════════════════════════════════════════════════╝
# EOF
#     exit 0
# fi

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
# === FLAGS POST-22 ===
DO_NJALLA_SETUP=false           # 00_18_01_setup_coretransact.sh
DO_HTTPS_HEADER=false           # 00_18_02_verificar_https_headers.sh
DO_HEALTH=false                 # 00_18_03_reporte_salud_vps.sh
DO_PGP=false                    # 00_18_04_generar_clave_pgp_njalla.sh
DO_DEPLOY_UPDATE=false          # 00_18_05_deploy_update.sh
DO_RESTART=false                # 00_18_06_restart_coretransapi.sh
DO_STATUS=false                 # 00_18_07_status_coretransapi.sh
DO_SSL_PORTS=false              # 00_18_08_check_ssl_ports.sh
DO_ALL_STATUS=false             # 00_18_09_all_status_coretransapi.sh

DO_CLEAN=false
DO_GUNICORN=false
DO_LOCAL_SSL=false
DO_CERT=false

if [[ "$@" =~ -[Y-Zy-z] ]]; then

# === DETENER SI NO HAY ARGUMENTOS Y SOLO MOSTRAR ENCABEZADO ===
if [[ $# -eq 0 ]]; then
    echo ""
    cat <<'EOF'
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║                    SCRIPT MAESTRO DE DESPLIEGUE - api_bank_h2               ║
# ║  Automatización total: setup, backups, deploy, limpieza y seguridad         ║
# ║  Soporte para 30 combinaciones de despliegue con alias `d_*`                ║
# ║  Ejecuta `deploy_menu` para selección interactiva con FZF                   ║
# ║  Ejecuta `d_help` para ver ejemplos combinados y sus parámetros             ║
# ╚═════════════════════════════════════════════════════════════════════════════╝
EOF
    exit 0
fi

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

    echo -e "\033[1;36mOPCIONES DISPONIBLES:\033[0m"
    echo -e "  \033[1;33m-a\033[0m, \033[1;33m--all\033[0m               Ejecutar sin confirmaciones interactivas"
    echo -e "  \033[1;33m-s\033[0m, \033[1;33m--step\033[0m              Activar modo paso a paso (pregunta todo)"
    echo -e "  \033[1;33m-d\033[0m, \033[1;33m--debug\033[0m             Mostrar diagnóstico y variables actuales"
    echo -e "  \033[1;33m-h\033[0m, \033[1;33m--help\033[0m              Mostrar esta ayuda y salir"

    echo -e "\033[1;36mTAREAS DE DESARROLLO LOCAL:\033[0m"
    echo -e "  \033[1;33m-L\033[0m, \033[1;33m--do-local\033[0m          Descargar archivos locales .json/.env"
    echo -e "  \033[1;33m-l\033[0m, \033[1;33m--do-load-local\033[0m     Subir archivos locales .json/.env"
    echo -e "  \033[1;33m-Q\033[0m, \033[1;33m--do-pgsql\033[0m          Configurar PostgreSQL local"
    echo -e "  \033[1;33m-I\033[0m, \033[1;33m--do-migra\033[0m          Aplicar migraciones Django"
    echo -e "  \033[1;33m-U\033[0m, \033[1;33m--do-create-user\033[0m    Crear usuario del sistema"

    echo -e "\033[1;36mBACKUPS:\033[0m"
    echo -e "  \033[1;33m-C\033[0m, \033[1;33m--do-clean\033[0m          Limpiar respaldos antiguos"
    echo -e "  \033[1;33m-Z\033[0m, \033[1;33m--do-zip\033[0m            Generar backups ZIP + SQL"

    echo -e "\033[1;36mDEPLOY HEROKU:\033[0m"
    echo -e "  \033[1;33m-S\033[0m, \033[1;33m--do-sync\033[0m           Sincronizar archivos locales"
    echo -e "  \033[1;33m-B\033[0m, \033[1;33m--do-bdd\033[0m            Sincronizar BDD remota"
    echo -e "  \033[1;33m-H\033[0m, \033[1;33m--do-heroku\033[0m         Desplegar a Heroku"
    echo -e "  \033[1;33m-u\033[0m, \033[1;33m--do-varher\033[0m         Configurar variables Heroku"

    echo -e "\033[1;36mENTORNO Y CONFIGURACIÓN:\033[0m"
    echo -e "  \033[1;33m-Y\033[0m, \033[1;33m--do-sys\033[0m            Actualizar sistema y dependencias"
    echo -e "  \033[1;33m-P\033[0m, \033[1;33m--do-ports\033[0m          Cerrar puertos abiertos conflictivos"
    echo -e "  \033[1;33m-D\033[0m, \033[1;33m--do-docker\033[0m         Cerrar contenedores abiertos conflictivos"
    echo -e "  \033[1;33m-M\033[0m, \033[1;33m--do-mac\033[0m            Cambiar MAC aleatoria"
    echo -e "  \033[1;33m-x\033[0m, \033[1;33m--do-ufw\033[0m            Configurar firewall UFW"
    echo -e "  \033[1;33m-p\033[0m, \033[1;33m--do-pem\033[0m            Generar claves PEM locales"
    echo -e "  \033[1;33m-E\033[0m, \033[1;33m--do-cert\033[0m           Generar certificados SSL locales"

    echo -e "\033[1;36mEJECUCIÓN Y TESTING:\033[0m"
    echo -e "  \033[1;33m-r\033[0m, \033[1;33m--do-local-ssl\033[0m      Ejecutar entorno local con SSL (Gunicorn + Nginx 8443) 🚀"
    echo -e "  \033[1;33m-G\033[0m, \033[1;33m--do-gunicorn\033[0m       Ejecutar Gunicorn"
    echo -e "  \033[1;33m-V\033[0m, \033[1;33m--do-verif-trans\033[0m    Verificar transferencias SEPA"

    echo -e "\033[1;36mPOST DEPLOY VPS:\033[0m"
    echo -e "  \033[1;33m-v\033[0m, \033[1;33m--do-vps\033[0m            Desplegar a VPS (Njalla)"
    echo -e "  \033[1;33m-N\033[0m, \033[1;33m--do-njalla\033[0m         Setup coretransapi"
    echo -e "  \033[1;33m-t\033[0m, \033[1;33m--do-headers\033[0m        Verifica encabezados HTTPS"
    echo -e "  \033[1;33m-e\033[0m, \033[1;33m--do-health\033[0m         Reporte de salud del VPS"
    echo -e "  \033[1;33m-g\033[0m, \033[1;33m--do-pgp\033[0m            Genera clave PGP Njalla"
    echo -e "  \033[1;33m-y\033[0m, \033[1;33m--do-update\033[0m         Ejecuta deploy incremental"
    echo -e "  \033[1;33m-j\033[0m, \033[1;33m--do-restart\033[0m        Reinicia servicio coretransapi"
    echo -e "  \033[1;33m-k\033[0m, \033[1;33m--do-status\033[0m         Estado del servicio coretransapi"
    echo -e "  \033[1;33m-m\033[0m, \033[1;33m--do-ssl\033[0m            Verifica certificados SSL y puertos"
    echo -e "  \033[1;33m-A\033[0m, \033[1;33m--do-allstatus\033[0m      Ejecuta todos los chequeos de status"
}




# === PARSEO DE ARGUMENTOS ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)             
# === DETENER SI NO HAY ARGUMENTOS Y SOLO MOSTRAR ENCABEZADO ===
if [[ $# -eq 0 ]]; then
    echo ""
    cat <<'EOF'
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║                    SCRIPT MAESTRO DE DESPLIEGUE - api_bank_h2               ║
# ║  Automatización total: setup, backups, deploy, limpieza y seguridad         ║
# ║  Soporte para 30 combinaciones de despliegue con alias `d_*`                ║
# ║  Ejecuta `deploy_menu` para selección interactiva con FZF                   ║
# ║  Ejecuta `d_help` para ver ejemplos combinados y sus parámetros             ║
# ╚═════════════════════════════════════════════════════════════════════════════╝
EOF
    exit 0
fi

PROMPT_MODE=false ;;
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
        -r|--do-local-ssl)    DO_LOCAL_SSL=true ;;
        -E|--do-cert)         DO_CERT=true ;;
        -N|--do-njalla)       DO_NJALLA_SETUP=true ;;
        -t|--do-headers)      DO_HTTPS_HEADER=true ;;
        -e|--do-health)       DO_HEALTH=true ;;
        -g|--do-pgp)          DO_PGP=true ;;
        -y|--do-update)       DO_DEPLOY_UPDATE=true ;;
        -j|--do-restart)      DO_RESTART=true ;;
        -k|--do-status)       DO_STATUS=true ;;
        -m|--do-ssl)          DO_SSL_PORTS=true ;;
        -A|--do-allstatus)    DO_ALL_STATUS=true ;;
        -h|--help)            usage; exit 0 ;;
        --menu)
            source ./scripts/aliases_deploy.sh
            deploy_menu
            exit 0
            ;;        
        *)
            echo -e "\\033[1;31m❌ Opción desconocida:\\033[0m $1"
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



if [[ "${DEBUG_MODE:-false}" == false ]]; then
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
        echo "VPN (proton0) activa. Conexión segura."
    elif ip a show tun0 &>/dev/null; then
        echo "VPN (tun0) activa. Conexión segura."
    else
        echo "❌ No hay VPN activa (ni proton0 ni tun0). Abortando despliegues sensibles."
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
        echo "❌ DEBUG está activo en producción. Revisa tu .env"
        exit 1
    fi
    if grep -q "localhost" "$archivo_env"; then
        echo "❌ ALLOWED_HOSTS contiene 'localhost'. No es seguro para producción."
        exit 1
    fi
    if ! grep -q "SECRET_KEY=" "$archivo_env"; then
        echo "❌ SECRET_KEY no está configurado en .env"
        exit 1
    fi
    echo "✔️ Configuración .env validada."
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



# === 01 ===
centrar_texto_coloreado $'\033[7;33mSISTEMA\033[0m'
centrar_texto "SISTEMA" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_SYS" "Actualizar sistema" "bash $SCRIPTS_DIR/00_01_sistema.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 02 ===
centrar_texto_coloreado $'\033[7;33mZIP\033[0m'
centrar_texto "ZIP" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_ZIP_SQL" "Crear zip y sql" "bash $SCRIPTS_DIR/00_02_zip_backup.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 03 ===
centrar_texto_coloreado $'\033[7;33mPUERTOS\033[0m'
centrar_texto "PUERTOS" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_PORTS" "Cerrar puertos" "bash $SCRIPTS_DIR/00_03_puertos.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 04 ===
centrar_texto_coloreado $'\033[7;33mCONTENEDORES\033[0m'
centrar_texto "CONTENEDORES" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_DOCKER" "Cerrar contenedores" "bash $SCRIPTS_DIR/00_04_container.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 05 ===
centrar_texto_coloreado $'\033[7;33mCAMBIO MAC\033[0m'
centrar_texto "CAMBIO MAC" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_MAC" "Cambiar MAC" "bash $SCRIPTS_DIR/00_05_mac.sh"
# echo -e "\n\n"
pausa_y_limpiar
verificar_vpn_segura
# === 06 ===
centrar_texto_coloreado $'\033[7;33mUFW\033[0m'
centrar_texto "UFW" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_UFW" "Configurar UFW" "bash $SCRIPTS_DIR/00_06_ufw.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 07 ===
centrar_texto_coloreado $'\033[7;33mPOSTGRES\033[0m'
centrar_texto "POSTGRES" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_PGSQL" "Configurar PostgreSQL" "bash $SCRIPTS_DIR/00_07_postgres.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 08 ===
centrar_texto_coloreado $'\033[7;33mMIGRACIONES\033[0m'
centrar_texto "MIGRACIONES" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_MIG" "Ejecutar migraciones" "bash $SCRIPTS_DIR/00_08_migraciones.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 09 ===
centrar_texto_coloreado $'\033[7;33mCARGAR LOCAL\033[0m'
centrar_texto "CARGAR LOCAL" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_RUN_LOCAL" "Subir bdd_local" "bash $SCRIPTS_DIR/00_09_cargar_json.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 10 ===
centrar_texto_coloreado $'\033[7;33mUSUARIO\033[0m'
centrar_texto "USUARIO" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_USER" "Crear Super Usuario" "bash $SCRIPTS_DIR/00_10_usuario.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 11 ===
centrar_texto_coloreado $'\033[7;33mRESPALDOS LOCAL\033[0m'
centrar_texto "RESPALDOS LOCAL" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_JSON_LOCAL" "Crear respaldo JSON local" "bash $SCRIPTS_DIR/00_11_hacer_json.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 12 ===
centrar_texto_coloreado $'\033[7;33mPEM JWKS\033[0m'
centrar_texto "PEM JWKS" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_PEM" "Generar PEM JWKS" "bash $SCRIPTS_DIR/00_12_pem.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 13 ===
centrar_texto_coloreado $'\033[7;33mVERIFICAR TRANSFERENCIAS\033[0m'
centrar_texto "VERIFICAR TRANSFERENCIAS" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_VERIF_TRANSF" "Verificar Transferencias" "bash $SCRIPTS_DIR/00_13_verificar_transferencias.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 14 ===
centrar_texto_coloreado $'\033[7;33mSINCRONIZACION COMPLETA\033[0m'
centrar_texto "SINCRONIZACION COMPLETA" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_SYNC_LOCAL" "Sincronizar Archivos Locales" "bash $SCRIPTS_DIR/00_14_sincronizacion_archivos.sh"
# echo -e "\n\n"
pausa_y_limpiar

verificar_vpn_segura
verificar_configuracion_segura
rotar_logs_si_grandes

# === 15 ===
centrar_texto_coloreado $'\033[7;33mVARIABLES A HEROKU\033[0m'
centrar_texto "VARIABLES A HEROKU" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_VARHER" "Subir variables a Heroku" "bash $SCRIPTS_DIR/00_15_variables_heroku.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 16 ===
centrar_texto_coloreado $'\033[7;33mSUBIR A HEROKU\033[0m'
centrar_texto "SUBIR A HEROKU" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_HEROKU" "Subir el proyecto a la web" "bash $SCRIPTS_DIR/00_16_subir_heroku.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 17 ===
centrar_texto_coloreado $'\033[7;33mSINCRONIZACION BDD WEB\033[0m'
centrar_texto "SINCRONIZACION BDD WEB" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_SYNC_REMOTE_DB" "Sincronizar BDD Remota" "bash $SCRIPTS_DIR/00_17_sincronizar_bdd.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 18 ===
centrar_texto_coloreado $'\033[7;33mVPS\033[0m'
centrar_texto "VPS" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_DEPLOY_VPS" "Desplegar en VPS" "bash $SCRIPTS_DIR/00_18_00_deploy_njalla.sh"
# echo -e "\n\n"
pausa_y_limpiar


# === SETUP COMPLETO CORETRANSAPI ===
centrar_texto_coloreado $'\033[7;34mSETUP COMPLETO CORETRANSAPI\033[0m'
centrar_texto "SETUP COMPLETO CORETRANSAPI" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_NJALLA_SETUP" "Setup completo coretransapi" "bash $SCRIPTS_DIR/00_18_01_setup_coretransact.sh"
pausa_y_limpiar


# === VERIFICAR HTTPS HEADERS ===
centrar_texto_coloreado $'\033[7;34mVERIFICAR HTTPS HEADERS\033[0m'
centrar_texto "VERIFICAR HTTPS HEADERS" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_HTTPS_HEADER" "Verificar HTTPS Headers" "bash $SCRIPTS_DIR/00_18_02_verificar_https_headers.sh"
pausa_y_limpiar


# === REPORTE DE SALUD DEL VPS ===
centrar_texto_coloreado $'\033[7;34mREPORTE DE SALUD DEL VPS\033[0m'
centrar_texto "REPORTE DE SALUD DEL VPS" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_HEALTH" "Reporte de Salud del VPS" "bash $SCRIPTS_DIR/00_18_03_reporte_salud_vps.sh"
pausa_y_limpiar


# === GENERAR CLAVE PGP NJALLA ===
centrar_texto_coloreado $'\033[7;34mGENERAR CLAVE PGP NJALLA\033[0m'
centrar_texto "GENERAR CLAVE PGP NJALLA" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_PGP" "Generar clave PGP Njalla" "bash $SCRIPTS_DIR/00_18_04_generar_clave_pgp_njalla.sh"
pausa_y_limpiar


# === DEPLOY INCREMENTAL ===
centrar_texto_coloreado $'\033[7;34mDEPLOY INCREMENTAL\033[0m'
centrar_texto "DEPLOY INCREMENTAL" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_DEPLOY_UPDATE" "Deploy incremental" "bash $SCRIPTS_DIR/00_18_05_deploy_update.sh"
pausa_y_limpiar


# === REINICIAR SERVICIO CORETRANSAPI ===
centrar_texto_coloreado $'\033[7;34mREINICIAR SERVICIO CORETRANSAPI\033[0m'
centrar_texto "REINICIAR SERVICIO CORETRANSAPI" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_RESTART" "Reiniciar servicio coretransapi" "bash $SCRIPTS_DIR/00_18_06_restart_coretransapi.sh"
pausa_y_limpiar


# === VERIFICAR ESTADO CORETRANSAPI ===
centrar_texto_coloreado $'\033[7;34mVERIFICAR ESTADO CORETRANSAPI\033[0m'
centrar_texto "VERIFICAR ESTADO CORETRANSAPI" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_STATUS" "Verificar estado coretransapi" "bash $SCRIPTS_DIR/00_18_07_status_coretransapi.sh"
pausa_y_limpiar


# === VERIFICAR SSL Y PUERTOS ===
centrar_texto_coloreado $'\033[7;34mVERIFICAR SSL Y PUERTOS\033[0m'
centrar_texto "VERIFICAR SSL Y PUERTOS" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_SSL_PORTS" "Verificar SSL y Puertos" "bash $SCRIPTS_DIR/00_18_08_check_ssl_ports.sh"
pausa_y_limpiar


# === STATUS COMPLETO CONSOLIDADO ===
centrar_texto_coloreado $'\033[7;34mSTATUS COMPLETO CONSOLIDADO\033[0m'
centrar_texto "STATUS COMPLETO CONSOLIDADO" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_ALL_STATUS" "Status completo consolidado" "bash $SCRIPTS_DIR/00_18_09_all_status_coretransapi.sh"
pausa_y_limpiar



# === 19 ===
centrar_texto_coloreado $'\033[7;33mCLEAN\033[0m'
centrar_texto "CLEAN" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_CLEAN" "Limpiar respaldos" "bash $SCRIPTS_DIR/00_19_borrar_zip_sql.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 20 ===
centrar_texto_coloreado $'\033[7;33mSSL\033[0m'
centrar_texto "SSL" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_CERT" "Generar Certificado" "bash $SCRIPTS_DIR/00_20_ssl.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 21 ===
centrar_texto_coloreado $'\033[7;33mLOCAL CON SSL\033[0m'
centrar_texto "LOCAL CON SSL" >> "$LOG_DEPLOY"
if [[ "$DO_LOCAL_SSL" == true && "$DO_GUNICORN" == true ]]; then
    echo -e "\033[1;31m❌ No puedes ejecutar DO_LOCAL_SSL y DO_GUNICORN al mismo tiempo.\033[0m"
    exit 1
fi
ejecutar_si_activo "DO_LOCAL_SSL" "Iniciar entorno local con Gunicorn + SSL" "bash $SCRIPTS_DIR/00_21_local_ssl.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 22 ===
centrar_texto_coloreado $'\033[7;33mGUNICORN\033[0m'
centrar_texto "GUNICORN" >> "$LOG_DEPLOY"
ejecutar_si_activo "DO_GUNICORN" "Iniciar Gunicorn, honeypot y livereload" "bash $SCRIPTS_DIR/00_22_gunicorn.sh"
# echo -e "\n\n"
pausa_y_limpiar

# === 23 ===
centrar_texto_coloreado $'\033[7;34mSCRIPT COMPLETO\033[0m'
centrar_texto "SCRIPT COMPLETO" >> "$LOG_DEPLOY"

URL_LOCAL="http://0.0.0.0:8000"
URL_HEROKU="https://apibank2-54644cdf263f.herokuapp.com/"
URL_NJALLA="https://api.coretransapi.com/"

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
