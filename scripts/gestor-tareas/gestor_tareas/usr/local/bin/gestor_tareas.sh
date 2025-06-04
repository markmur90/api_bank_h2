#!/bin/bash

# gestor_tareas.sh
# MIT License – SHA-256: AÑADIREMOS TRAS FINALIZAR

TASK_FILE="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/tareas_gestor_000.txt"
CONFIG_FILE="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/gestor_config_000.txt"
ACTIVE_FILE="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/gestor_activo_000.flag"
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
    local lista=$(awk -F '|' '{print NR, $1, $2}' "$TASK_FILE" | sed 's/|/ - /g' | paste -sd'\n')
    local duracion=60  # segundos hasta que se cierre

    response=$(zenity --list --title="Gestor de Tareas 000" \
        --text="Sesión activa: $(uptime -p)\nIntervalo: ${INTERVAL} minutos\n\nTareas:\n$lista" \
        --column="Acción" --column="Descripción" \
        Agregar "Nueva tarea" \
        Editar "Modificar una tarea" \
        Eliminar "Eliminar tarea" \
        Actualizar "Marcar tarea como completada" \
        Tiempo "Cambiar intervalo de recordatorio" \
        Desactivar "Cerrar gestor" \
        Aceptar "Aceptar y cerrar esta ventana" \
        --timeout=$duracion \
        --width=500 --height=400)

    case $response in
        Agregar)
            nueva=$(zenity --entry --title="Agregar Tarea" --text="Descripción de la tarea:")
            [ -n "$nueva" ] && echo "$nueva|pendiente" >> "$TASK_FILE"
            ;;
        Editar)
            sel=$(zenity --entry --title="Editar Tarea" --text="Número de tarea a editar:")
            linea=$(sed -n "${sel}p" "$TASK_FILE")
            nueva=$(zenity --entry --title="Editar Tarea" --text="Nueva descripción:" --entry-text="$(echo $linea | cut -d'|' -f1)")
            [ -n "$nueva" ] && sed -i "${sel}s|.*|$nueva|pendiente|" "$TASK_FILE"
            ;;
        Eliminar)
            sel=$(zenity --entry --title="Eliminar Tarea" --text="Número de tarea a eliminar:")
            sed -i "${sel}d" "$TASK_FILE"
            ;;
        Actualizar)
            sel=$(zenity --entry --title="Actualizar Tarea" --text="Número de tarea completada:")
            sed -i "${sel}s|pendiente|completada|" "$TASK_FILE"
            ;;
        Tiempo)
            nuevo=$(zenity --entry --title="Intervalo" --text="Nuevo tiempo en minutos:" --entry-text="$INTERVAL")
            echo $nuevo > "$CONFIG_FILE"
            INTERVAL=$nuevo
            ;;
        Desactivar)
            rm -f "$ACTIVE_FILE"
            exit 0
            ;;
    esac
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
