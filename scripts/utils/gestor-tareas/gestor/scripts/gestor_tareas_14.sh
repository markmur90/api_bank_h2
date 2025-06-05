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

PROYECTO=$(zenity --entry --title="Seleccionar proyecto 14"     --text="Proyecto actual (nuevo o existente):"     --entry-text="$(get_proyectos | head -n1)")

[ -z "$PROYECTO" ] && exit 1

PROY_DIR="$BASE_DIR/$PROYECTO"
TASK_FILE="$PROY_DIR/tareas_14.txt"
CONFIG_FILE="$PROY_DIR/config_14.txt"
TIME_LOG="$PROY_DIR/tiempos_14.log"
ACTIVE_FILE="$AP_H2_DIR/scripts/gestor-tareas/gestor/gestor_activo_$PROYECTO.flag"
mkdir -p "$PROY_DIR"
touch "$TASK_FILE" "$CONFIG_FILE" "$TIME_LOG"
DEFAULT_INTERVAL=5
INTERVAL=$(cat "$CONFIG_FILE" 2>/dev/null || echo $DEFAULT_INTERVAL)
[[ -z "$INTERVAL" ]] && INTERVAL=$DEFAULT_INTERVAL
echo "$INTERVAL" > "$CONFIG_FILE"

notify_sound() {
    command -v paplay >/dev/null && paplay /usr/share/sounds/freedesktop/stereo/complete.oga ||     command -v aplay >/dev/null && aplay /usr/share/sounds/alsa/Front_Center.wav ||     command -v ffplay >/dev/null && ffplay -nodisp -autoexit /usr/share/sounds/*.wav >/dev/null 2>&1
}

calcular_tiempo_total() {
    awk '{s+=$1} END {print s}' "$TIME_LOG"
}

formatear_minutos() {
    local min=$1
    printf "%dh%02dm" $((min/60)) $((min%60))
}

ordenar_archivo() {
    sort -t'|' -k2 "$TASK_FILE" > "$TASK_FILE.tmp" && mv "$TASK_FILE.tmp" "$TASK_FILE"
}

mostrar_gestor() {
    local ahora=$(date +%s)
    local minutos_sesion=$(( (ahora - INICIO_EPOCH) / 60 ))
    local acumulado=$(calcular_tiempo_total)
    local minutos_totales=$((acumulado + minutos_sesion))

    HORA_LOCAL=$(date '+%H:%M')
    HORA_BOGOTA=$(TZ=America/Bogota date '+%H:%M')
    local encabezado="Proyecto: $PROYECTO | Sesión: $(formatear_minutos $minutos_sesion) | Total: $(formatear_minutos $minutos_totales)
Intervalo: ${INTERVAL} min | Hora local: $HORA_LOCAL (Bogotá: $HORA_BOGOTA)"

    mapfile -t tareas < <(awk -F'|' 'NF==3 {print NR "|" $1 "|" $2 "|" $3}' "$TASK_FILE" | sort -t'|' -k3)

    if [[ ${#tareas[@]} -eq 0 ]]; then
        zenity --info --title="Gestor de Tareas" --text="No hay tareas registradas." --width=300
        return 0
    fi

    tarea_seleccionada=$(zenity --list         --title="Tareas – $PROYECTO"         --text="$encabezado"         --column="ID" --column="Descripción" --column="Estado" --column="Creación"         "${tareas[@]}"         --width=850 --height=500)

    [[ -z "$tarea_seleccionada" ]] && return 0
    id=$(echo "$tarea_seleccionada" | cut -d'|' -f1)

    accion=$(zenity --list --title="Acción sobre tarea #$id"         --text="Selecciona qué hacer:"         --column="Acción" "Editar" "Actualizar" "Eliminar" "Cancelar"         --width=300 --height=200)

    case $accion in
        Editar)
            original=$(sed -n "${id}p" "$TASK_FILE")
            nueva=$(zenity --entry --title="Editar tarea"                 --text="Nueva descripción:"                 --entry-text="$(echo "$original" | cut -d'|' -f1)")
            estado=$(echo "$original" | cut -d'|' -f2)
            fecha=$(echo "$original" | cut -d'|' -f3)
            [[ -n "$nueva" ]] && sed -i "${id}s|.*|${nueva}|${estado}|${fecha}|" "$TASK_FILE"
            ;;
        Actualizar)
            sed -i "${id}s|pendiente|completada|" "$TASK_FILE"
            ;;
        Eliminar)
            sed -i "${id}d" "$TASK_FILE"
            ;;
        Cancelar)
            return 0
            ;;
    esac
    ordenar_archivo
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

zenity --entry --title="Agregar nueva tarea"     --text="Descripción de la nueva tarea:"     --entry-text="" | while read desc; do
        [[ -n "$desc" ]] && echo "$desc|pendiente|$(date '+%Y-%m-%d %H:%M')" >> "$TASK_FILE"
    done

ordenar_archivo
activar_gestor
