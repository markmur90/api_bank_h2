#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="./scripts"

# Flags de ejecución
EJECUTAR_TODO=false
RUN_DIAG=false
RUN_POSTGRES=false
RUN_RESET_DB=false
RUN_SYNC=false
RUN_ZIP=false
RUN_SUPERUSER=false
RUN_CARGAR_LOCAL=false
RUN_DEPLOY=false
RUN_GUNICORN=false
RUN_MAC=false
RUN_LIMPIAR=false
RUN_HEROKUWEB=false

# Interpretar flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all) EJECUTAR_TODO=true ;;
        -D) RUN_DIAG=true ;;
        -P) RUN_POSTGRES=true ;;
        -B) RUN_RESET_DB=true ;;
        -S) RUN_SYNC=true ;;
        -Z) RUN_ZIP=true ;;
        -U) RUN_SUPERUSER=true ;;
        -L) RUN_CARGAR_LOCAL=true ;;
        -H) RUN_DEPLOY=true ;;
        -G) RUN_GUNICORN=true ;;
        -M) RUN_MAC=true ;;
        -C) RUN_LIMPIAR=true ;;
        -W) RUN_HEROKUWEB=true ;;
        -h|--help)
            echo "Uso: $0 [flags]"
            echo ""
            echo "  -a, --all           Ejecutar todos los scripts"
            echo "  -D                  Diagnóstico del entorno"
            echo "  -P                  Configurar entorno y PostgreSQL"
            echo "  -B                  Resetear base de datos"
            echo "  -S                  Sincronizar archivos locales"
            echo "  -Z                  Crear respaldo ZIP de base de datos"
            echo "  -U                  Crear superusuario de Django"
            echo "  -L                  Cargar respaldo local (bdd_local.json)"
            echo "  -H                  Deploy en Heroku"
            echo "  -G                  Iniciar Gunicorn"
            echo "  -M                  Cambiar dirección MAC"
            echo "  -C                  Limpiar respaldos antiguos"
            echo "  -W                  Abrir sitio Heroku en navegador"
            echo ""
            exit 0 ;;
    esac
    shift
done

# Si -a está activado, se ejecutan todos
if [[ "$EJECUTAR_TODO" == true ]]; then
    RUN_DIAG=true
    RUN_POSTGRES=true
    RUN_RESET_DB=true
    RUN_SYNC=true
    RUN_ZIP=true
    RUN_SUPERUSER=true
    RUN_CARGAR_LOCAL=true
    RUN_DEPLOY=true
    RUN_GUNICORN=true
    RUN_MAC=true
    RUN_LIMPIAR=true
    RUN_HEROKUWEB=true
fi

ejecutar_script() {
    local script_name="$1"
    local description="$2"
    if [[ -f "$SCRIPTS_DIR/$script_name" ]]; then
        echo -e "\033[1;34m➡️ Ejecutando: $description ($script_name)\033[0m"
        bash "$SCRIPTS_DIR/$script_name"
        echo -e "\033[1;32m✅ Completado: $description\033[0m\n"
    else
        echo -e "\033[1;31m❌ Script no encontrado: $SCRIPTS_DIR/$script_name\033[0m"
    fi
}

[[ "$RUN_DIAG" == true ]] && ejecutar_script "diagnostico_entorno.sh" "Diagnóstico del entorno"
[[ "$RUN_POSTGRES" == true ]] && ejecutar_script "configurar_postgres.sh" "Configuración PostgreSQL"
[[ "$RUN_RESET_DB" == true ]] && ejecutar_script "resetear_bd.sh" "Reset de base de datos"
[[ "$RUN_SYNC" == true ]] && ejecutar_script "sincronizar_local.sh" "Sincronización local"
[[ "$RUN_ZIP" == true ]] && ejecutar_script "zip_backup_total.sh" "Backup y compresión ZIP"
[[ "$RUN_SUPERUSER" == true ]] && ejecutar_script "crear_usuario.sh" "Creación de superusuario"
[[ "$RUN_CARGAR_LOCAL" == true ]] && ejecutar_script "cargar_local.sh" "Carga de respaldo local"
[[ "$RUN_DEPLOY" == true ]] && ejecutar_script "deploy_heroku.sh" "Deploy a Heroku"
[[ "$RUN_GUNICORN" == true ]] && ejecutar_script "iniciar_gunicorn.sh" "Inicio Gunicorn"
[[ "$RUN_MAC" == true ]] && ejecutar_script "cambiar_mac.sh" "Cambio de dirección MAC"
[[ "$RUN_LIMPIAR" == true ]] && ejecutar_script "limpiar_backups.sh" "Limpieza de respaldos antiguos"
[[ "$RUN_HEROKUWEB" == true ]] && ejecutar_script "abrir_heroku.sh" "Abrir sitio Heroku"

