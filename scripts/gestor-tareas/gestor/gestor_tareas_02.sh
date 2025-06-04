#!/bin/bash
BASE_DIR="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/.gestor_tareas"
mkdir -p "$BASE_DIR"

# Obtener lista de proyectos
get_proyectos() {
    ls "$BASE_DIR" 2>/dev/null || echo "default"
}

# Elegir proyecto
PROYECTO=$(zenity --entry --title="Seleccionar proyecto 02" \
    --text="Proyecto actual (nuevo o existente):" \
    --entry-text="$(get_proyectos | head -n1)")

[ -z "$PROYECTO" ] && exit 1

# Archivos por proyecto
PROY_DIR="$BASE_DIR/$PROYECTO"
TASK_FILE="$PROY_DIR/tareas_02.txt"
CONFIG_FILE="$PROY_DIR/config_02.txt"
TIME_LOG="$PROY_DIR/tiempos_02.log"
ACTIVE_FILE="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/gestor_activo_$PROYECTO.flag"
mkdir -p "$PROY_DIR"
touch "$TASK_FILE" "$CONFIG_FILE" "$TIME_LOG" "$ACTIVE_FILE"

DEFAULT_INTERVAL=10
DEFAULT_TIMEOUT=60
INTERVAL=$(cat "$CONFIG_FILE" 2>/dev/null || echo $DEFAULT_INTERVAL)
TIMEOUT=$DEFAULT_TIMEOUT

# Soporte --interval y --timeout
for arg in "$@"; do
    [[ $arg =~ ^--interval=([0-9]+)$ ]] && INTERVAL="${BASH_REMATCH[1]}"
    [[ $arg =~ ^--timeout=([0-9]+)$ ]] && TIMEOUT="${BASH_REMATCH[1]}"
done
echo "$INTERVAL" > "$CONFIG_FILE"

notify_sound() {
    command -v paplay && paplay /usr/share/sounds/freedesktop/stereo/complete.oga || \
    command -v aplay && aplay /usr/share/sounds/alsa/Front_Center.wav || \
    command -v ffplay && ffplay -nodisp -autoexit /usr/share/sounds/*.wav >/dev/null 2>&1
}

calcular_tiempo_total() {
    awk '{s+=$1} END {print s}' "$TIME_LOG"
}

formatear_minutos() {
    local min=$1
    printf "%dh%02dm" $((min/60)) $((min%60))
}

mostrar_gestor() {
    local ahora=$(date +%s)
    local minutos_sesion=$(( (ahora - INICIO_EPOCH) / 60 ))
    local acumulado=$(calcular_tiempo_total)
    local minutos_totales=$((acumulado + minutos_sesion))
    local encabezado="Proyecto: $PROYECTO | Sesión: $(formatear_minutos $minutos_sesion) | Total: $(formatear_minutos $minutos_totales) | Intervalo: ${INTERVAL}m"

    local lista=$(awk -F '|' '{print NR ". " $1 " - " $2}' "$TASK_FILE" | paste -sd'\n')

    local options=$(zenity --forms --title="Gestor de Tareas 02 – $PROYECTO" \
        --text="$encabezado" \
        --add-combo="Acción" --combo-values="Agregar|Editar|Eliminar|Actualizar|Tiempo|Desactivar" \
        --add-entry="Dato (número o texto según acción)" \
        --timeout=$TIMEOUT \
        --separator="|" \
        --width=600)

    IFS="|" read -r accion dato <<< "$options"

    case $accion in
        Agregar)
            [ -n "$dato" ] && echo "$dato|pendiente" >> "$TASK_FILE"
            notify-send "[$PROYECTO] Tarea Agregada" "$dato"
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
            case $INTERVAL in
                5) INTERVAL=10 ;; 10) INTERVAL=15 ;; 15) INTERVAL=20 ;;
                20) INTERVAL=25 ;; 25) INTERVAL=30 ;; 30) INTERVAL=35 ;;
                35) INTERVAL=40 ;; 40) INTERVAL=45 ;; 45) INTERVAL=50 ;;
                50) INTERVAL=55 ;; 55) INTERVAL=60 ;; 60|*) INTERVAL=5 ;;
            esac
            echo "$INTERVAL" > "$CONFIG_FILE"
            notify-send "[$PROYECTO] Intervalo actualizado" "${INTERVAL} minutos"
            ;;
        Desactivar)
            rm -f "$ACTIVE_FILE"
            FIN_EPOCH=$(date +%s)
            DURACION=$(( (FIN_EPOCH - INICIO_EPOCH) / 60 ))
            echo "$DURACION" >> "$TIME_LOG"
            notify-send "[$PROYECTO] Gestor Desactivado" "Sesión: $(formatear_minutos $DURACION)"
            exit 0
            ;;
    esac

    zenity --info --title="Tareas – $PROYECTO" \
        --text="Tareas:\n\n$lista" \
        --ok-label="Aceptar" \
        --width=500 --height=350
}

activar_gestor() {
    INICIO_EPOCH=$(date +%s)
    while [ -f "$ACTIVE_FILE" ]; do
        mostrar_gestor
        notify_sound
        sleep "${INTERVAL}m"
    done
}

activar_gestor
