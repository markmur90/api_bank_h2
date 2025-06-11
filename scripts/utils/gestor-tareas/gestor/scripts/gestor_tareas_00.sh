#!/bin/bash
set -o errexit -o nounset -o pipefail
export SHELL=/bin/bash

# -----------------------------------------------------------------------------
# Script: gestor_tareas_02.sh
# Propósito: Gestor de tareas gráfico con Zenity, por proyecto.
# - Selecciona o crea un proyecto.
# - Agrega/edita/elimina/actualiza tareas en archivos de texto.
# - Registra tiempo de ejecución por sesión.
# - Cicla intervalo de notificaciones.
# - Desactiva el gestor cuando se elija.
# -----------------------------------------------------------------------------

# 1. Comprobar entorno gráfico
if [ -z "${DISPLAY:-}" ]; then
  echo "ERROR: no se detecta un entorno gráfico (DISPLAY no definido)." >&2
  exit 1
fi

# 2. Definir directorio base oculto para proyectos

AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"


SCRIPT_NAME="$(basename "$0")"
BASE_DIR="$GE_LG_DIR/$SCRIPT_NAME"
mkdir -p "$BASE_DIR"


TASK_FILE="$AP_H2_DIR/scripts/gestor-tareas/gestor/tareas_gestor_00.txt"
CONFIG_FILE="$AP_H2_DIR/scripts/gestor-tareas/gestor/gestor_config_00.txt"
ACTIVE_FILE="$AP_H2_DIR/scripts/gestor-tareas/gestor/gestor_activo_00.flag"
touch "$TASK_FILE"
touch "$CONFIG_FILE"

DEFAULT_INTERVAL=10 # minutos
INTERVAL=$(cat "$CONFIG_FILE" 2>/dev/null || echo $DEFAULT_INTERVAL)

notify_sound() {
    command -v paplay && paplay /usr/share/sounds/freedesktop/stereo/complete.oga || \
    command -v aplay && aplay /usr/share/sounds/alsa/Front_Center.wav || \
    command -v ffplay && ffplay -nodisp -autoexit /usr/share/sounds/*.wav >/dev/null 2>&1
}

mostrar_gestor() {
    local duracion=60
    local lista=$(awk -F '|' '{print NR ". " $1 " - " $2}' "$TASK_FILE" | paste -sd'\n')

    options=$(zenity --forms --title="Gestor de Tareas 00" \
        --text="Sesión activa: $(uptime -p)     Intervalo: ${INTERVAL} minutos" \
        --add-combo="Acción" --combo-values="Agregar|Editar|Eliminar|Actualizar|Tiempo|Desactivar" \
        --add-entry="Dato (número o texto según acción)" \
        --forms-date-format="%Y-%m-%d" \
        --timeout=$duracion \
        --separator="|" \
        --width=550)

    IFS="|" read -r accion dato <<< "$options"

    case $accion in
        Agregar)
            [ -n "$dato" ] && echo "$dato|pendiente" >> "$TASK_FILE"
            notify-send "Tarea Agregada" "$dato"
            ;;
        Editar)
            orig=$(sed -n "${dato}p" "$TASK_FILE")
            nueva=$(zenity --entry --title="Editar" --text="Nueva descripción:" --entry-text="$(echo $orig | cut -d'|' -f1)")
            [ -n "$nueva" ] && sed -i "${dato}s|.*|$nueva|pendiente|" "$TASK_FILE"
            ;;
        Eliminar)
            sed -i "${dato}d" "$TASK_FILE"
            ;;
        Actualizar)
            sed -i "${dato}s|pendiente|completada|" "$TASK_FILE"
            ;;
        Tiempo)
            echo "$dato" > "$CONFIG_FILE"
            INTERVAL=$dato
            ;;
        Desactivar)
            rm -f "$ACTIVE_FILE"
            notify-send "Gestor Desactivado" "Hasta luego"
            exit 0
            ;;
    esac

    # Mostrar tareas y botón Aceptar
    zenity --info --title="Tareas actuales" \
        --text="Tareas:\n\n$lista" \
        --ok-label="Aceptar" \
        --width=500
}

activar_gestor() {
    touch "$ACTIVE_FILE"
    while [ -f "$ACTIVE_FILE" ]; do
        mostrar_gestor
        notify_sound
        sleep "${INTERVAL}m"
    done
}

activar_gestor
