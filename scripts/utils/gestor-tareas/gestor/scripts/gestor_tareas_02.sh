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

# 3. Obtener lista de proyectos (solo directorios dentro de BASE_DIR)
get_proyectos() {
  find "$BASE_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null || echo "default"
}

# 4. Pedir nombre del proyecto (nuevo o existente)
PROYECTO=$(/usr/bin/zenity --entry \
  --title="Seleccionar proyecto 02" \
  --text="Proyecto actual (nuevo o existente):" \
  --entry-text="$(get_proyectos | head -n1)")

[ -z "$PROYECTO" ] && exit 1

# 5. Definir rutas específicas del proyecto
PROY_DIR="$BASE_DIR/$PROYECTO"
TASK_FILE="$PROY_DIR/tareas_02.txt"
CONFIG_FILE="$PROY_DIR/config_02.txt"
TIME_LOG="$PROY_DIR/tiempos_02.log"
ACTIVE_FILE="$PROY_DIR/gestor_activo.flag"

mkdir -p "$PROY_DIR"
touch "$TASK_FILE" "$CONFIG_FILE" "$TIME_LOG" "$ACTIVE_FILE"

# 6. Intervalo (minutos) y timeout para Zenity
DEFAULT_INTERVAL=10
DEFAULT_TIMEOUT=60
INTERVAL=$(cat "$CONFIG_FILE" 2>/dev/null || echo $DEFAULT_INTERVAL)
TIMEOUT=$DEFAULT_TIMEOUT

# Soporte para --interval=<n> y --timeout=<n>
for arg in "$@"; do
  [[ $arg =~ ^--interval=([0-9]+)$ ]] && INTERVAL="${BASH_REMATCH[1]}"
  [[ $arg =~ ^--timeout=([0-9]+)$ ]] && TIMEOUT="${BASH_REMATCH[1]}"
done
echo "$INTERVAL" > "$CONFIG_FILE"

# =============================================================================
#  Funciones auxiliares
# =============================================================================

# Función: reproducir sonido al finalizar cada ciclo
notify_sound() {
  if command -v paplay >/dev/null 2>&1; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga
  elif command -v aplay >/dev/null 2>&1; then
    aplay /usr/share/sounds/alsa/Front_Center.wav
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit /usr/share/sounds/*.wav >/dev/null 2>&1
  fi
}

# Función: suma total de minutos guardados en TIME_LOG
calcular_tiempo_total() {
  /usr/bin/awk '{s+=$1} END {print s}' "$TIME_LOG"
}

# Función: formatea minutos a "XhYYm"
formatear_minutos() {
  local min=$1
  printf "%dh%02dm" $((min/60)) $((min%60))
}

# Función: muestra la interfaz principal de Zenity y procesa acciones
mostrar_gestor() {
  INICIO_EPOCH=${INICIO_EPOCH:-$(date +%s)}
  local ahora
  ahora=$(date +%s)
  local minutos_sesion=$(( (ahora - INICIO_EPOCH) / 60 ))
  local acumulado
  acumulado=$(calcular_tiempo_total)
  local minutos_totales=$((acumulado + minutos_sesion))

  local encabezado
  encabezado="Proyecto: $PROYECTO | Sesión: $(formatear_minutos $minutos_sesion) | Total: $(formatear_minutos $minutos_totales) | Intervalo: ${INTERVAL}m"

  # Listar tareas: "1. descripción - estado"
  local lista
  lista=$(/usr/bin/awk -F '|' '{print NR ". " $1 " - " $2}' "$TASK_FILE" | paste -sd'\n')

  # Mostrar formulario Zenity
  local options
  options=$(/usr/bin/zenity --forms \
    --title="Gestor de Tareas 02 – $PROYECTO" \
    --text="$encabezado" \
    --add-combo="Acción" --combo-values="Agregar|Editar|Eliminar|Actualizar|Tiempo|Desactivar" \
    --add-entry="Dato (número o texto según acción)" \
    --timeout="$TIMEOUT" \
    --separator="|" \
    --width=600)

  IFS="|" read -r accion dato <<< "$options"

  case $accion in
    Agregar)
      if [ -n "$dato" ]; then
        echo "$dato|pendiente" >> "$TASK_FILE"
        /usr/bin/notify-send "[$PROYECTO] Tarea Agregada" "$dato"
      fi
      ;;
    Editar)
      # Obtener línea original y descripción
      local orig desc_orig nueva safe_nueva
      orig=$(/usr/bin/sed -n "${dato}p" "$TASK_FILE")
      desc_orig="${orig%%|*}"
      nueva=$(/usr/bin/zenity --entry \
        --title="Editar Tarea – Línea $dato" \
        --text="Descripción actual: $desc_orig\n\nEscribe la nueva:" \
        --entry-text="$desc_orig")
      if [ -n "$nueva" ]; then
        # Escapar '|' en la nueva descripción
        safe_nueva="${nueva//|/\\|}"
        /usr/bin/sed -i "${dato}s|.*|${safe_nueva}|pendiente|" "$TASK_FILE"
      fi
      ;;
    Eliminar)
      /usr/bin/sed -i "${dato}d" "$TASK_FILE"
      ;;
    Actualizar)
      /usr/bin/sed -i "${dato}s|pendiente|completada|" "$TASK_FILE"
      ;;
    Tiempo)
      case $INTERVAL in
        5)  INTERVAL=10 ;;
        10) INTERVAL=15 ;;
        15) INTERVAL=20 ;;
        20) INTERVAL=25 ;;
        25) INTERVAL=30 ;;
        30) INTERVAL=35 ;;
        35) INTERVAL=40 ;;
        40) INTERVAL=45 ;;
        45) INTERVAL=50 ;;
        50) INTERVAL=55 ;;
        55) INTERVAL=60 ;;
        60|*) INTERVAL=5 ;;
      esac
      echo "$INTERVAL" > "$CONFIG_FILE"
      /usr/bin/notify-send "[$PROYECTO] Intervalo actualizado" "${INTERVAL} minutos"
      ;;
    Desactivar)
      rm -f "$ACTIVE_FILE"
      local FIN_EPOCH DURACION
      FIN_EPOCH=$(date +%s)
      DURACION=$(( (FIN_EPOCH - INICIO_EPOCH) / 60 ))
      echo "$DURACION" >> "$TIME_LOG"
      /usr/bin/notify-send "[$PROYECTO] Gestor Desactivado" "Sesión: $(formatear_minutos $DURACION)"
      exit 0
      ;;
  esac

  # Mostrar lista actual de tareas en un diálogo informativo
  /usr/bin/zenity --info --title="Tareas – $PROYECTO" \
    --text="Tareas:\n\n$lista" \
    --ok-label="Aceptar" \
    --width=500 --height=350
}

# Función principal: cicla cada $INTERVAL minutos mientras exista el flag activo
activar_gestor() {
  INICIO_EPOCH=$(date +%s)
  while [ -f "$ACTIVE_FILE" ]; do
    mostrar_gestor
    notify_sound
    sleep "${INTERVAL}m"
  done
}

# Arrancar el bucle principal
activar_gestor
