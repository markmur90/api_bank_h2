#!/bin/bash

# gestor_tareas.sh
# Gestor de tareas con zenity y notificaciones
# MIT License – SHA-256 se genera en empaquetado

TASK_FILE="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/tareas_gestor_00.txt"
CONFIG_FILE="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/gestor_config_00.txt"
ACTIVE_FILE="$HOME/api_bank_h2/scripts/gestor-tareas/gestor/gestor_activo_00.flag"
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
