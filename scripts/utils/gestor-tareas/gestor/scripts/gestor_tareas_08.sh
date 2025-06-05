#!/usr/bin/env bash
set -e

export DISPLAY=:0.0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

exec 2>/dev/null

BASE_DIR="$AP_H2_DIR/scripts/gestor-tareas/gestor/.gestor_tareas"
mkdir -p "$BASE_DIR"

get_proyectos() {
    ls "$BASE_DIR" 2>/dev/null || echo "default"
}

PROYECTO=$(zenity --entry --title="Seleccionar proyecto 08" \
    --text="Proyecto actual (nuevo o existente):" \
    --entry-text="$(get_proyectos | head -n1)")

[ -z "$PROYECTO" ] && exit 1

PROY_DIR="$BASE_DIR/$PROYECTO"
TASK_FILE="$PROY_DIR/tareas_08.txt"
CONFIG_FILE="$PROY_DIR/config_08.txt"
TIME_LOG="$PROY_DIR/tiempos_08.log"
ACTIVE_FILE="$AP_H2_DIR/scripts/gestor-tareas/gestor/gestor_activo_$PROYECTO.flag"
mkdir -p "$PROY_DIR"
touch "$TASK_FILE" "$CONFIG_FILE" "$TIME_LOG"
DEFAULT_INTERVAL=5
INTERVAL=$(cat "$CONFIG_FILE" 2>/dev/null || echo $DEFAULT_INTERVAL)
[[ -z "$INTERVAL" ]] && INTERVAL=$DEFAULT_INTERVAL
echo "$INTERVAL" > "$CONFIG_FILE"

notify_sound() {
    command -v paplay >/dev/null && paplay /usr/share/sounds/freedesktop/stereo/complete.oga || \
    command -v aplay >/dev/null && aplay /usr/share/sounds/alsa/Front_Center.wav || \
    command -v ffplay >/dev/null && ffplay -nodisp -autoexit /usr/share/sounds/*.wav >/dev/null 2>&1
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

    local hora_local=$(date +'%H:%M')
    local hora_bogota=$(TZ=America/Bogota date +'%H:%M')

    local encabezado="Proyecto: $PROYECTO | Sesión: $(formatear_minutos $minutos_sesion) | Total: $(formatear_minutos $minutos_totales) | Intervalo: ${INTERVAL}m
    Hora actual: $hora_local | Hora Bogotá: $hora_bogota"

    local lista_raw=($(awk -F'|' '{printf "%d|%s|%s\n", NR, $1, $2}' "$TASK_FILE"))
    local seleccion=$(zenity --list --title="Tareas – $PROYECTO" \
        --text="$encabezado" \
        --column="N°" --column="Descripción" --column="Estado" \
        "${lista_raw[@]}" \
        --width=600 --height=400)

    # Si se cierra o no se selecciona nada, simplemente retorna
    [ -z "$seleccion" ] && return 0

    num=$(echo "$seleccion" | cut -d'|' -f1)

    accion=$(zenity --list --title="Acción para tarea $num" \
        --text="¿Qué querés hacer con la tarea seleccionada?" \
        --radiolist \
        --column="Sel" --column="Acción" TRUE "Editar" FALSE "Actualizar" FALSE "Eliminar" \
        --width=300)

    case $accion in
        Editar)
            orig=$(sed -n "${num}p" "$TASK_FILE")
            nueva=$(zenity --entry --title="Editar" --text="Nueva descripción:" --entry-text="$(echo $orig | cut -d'|' -f1)")
            [ -n "$nueva" ] && sed -i "${num}s|.*|$nueva|pendiente|" "$TASK_FILE"
            ;;
        Actualizar)
            sed -i "${num}s|pendiente|completada|" "$TASK_FILE"
            ;;
        Eliminar)
            sed -i "${num}d" "$TASK_FILE"
            ;;
    esac

    extra=$(zenity --list --title="Opciones Extra" --text="¿Querés hacer algo más?" \
        --column="Opción" "Agregar nueva tarea" "Cambiar intervalo" "Desactivar" "Salir sin cambios" \
        --width=300)

    case $extra in
        "Agregar nueva tarea")
            nueva=$(zenity --entry --title="Agregar tarea" --text="Descripción:")
            [ -n "$nueva" ] && echo "$nueva|pendiente" >> "$TASK_FILE"
            ;;
        "Cambiar intervalo")
            case $INTERVAL in
                5) INTERVAL=10 ;; 10) INTERVAL=15 ;; 15) INTERVAL=20 ;;
                20) INTERVAL=25 ;; 25) INTERVAL=30 ;; 30) INTERVAL=35 ;;
                35) INTERVAL=40 ;; 40) INTERVAL=45 ;; 45) INTERVAL=50 ;;
                50) INTERVAL=55 ;; 55) INTERVAL=60 ;; 60|*) INTERVAL=5 ;;
            esac
            echo "$INTERVAL" > "$CONFIG_FILE"
            notify-send "[$PROYECTO] Intervalo actualizado" "${INTERVAL} minutos"
            ;;
        "Desactivar")
            rm -f "$ACTIVE_FILE"
            FIN_EPOCH=$(date +%s)
            DURACION=$(( (FIN_EPOCH - INICIO_EPOCH) / 60 ))
            echo "$DURACION" >> "$TIME_LOG"
            notify-send "[$PROYECTO] Gestor Desactivado" "Sesión: $(formatear_minutos $DURACION)"
            return 1
            ;;
    esac
}

activar_gestor() {
    touch "$ACTIVE_FILE"
    INICIO_EPOCH=$(date +%s)
    while [ -f "$ACTIVE_FILE" ]; do
        mostrar_gestor
        [[ $? -ne 0 ]] && break
        notify_sound
        sleep "${INTERVAL}m"
    done
}

activar_gestor
