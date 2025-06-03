#!/usr/bin/env bash
set +e

# # --- logging ---
# mkdir -p "$HOME/logs_notificadores"
# LOG_FILE="$HOME/logs_notificadores/$(basename "$0").log"
# exec > >(tee -a "$LOG_FILE") 2>&1
# echo -e "\n🔄 Inicio $(date '+%F %T')"

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus


MENSAJE="${1:-⏰ Recordatorio: tiempo transcurrido}"
INTERVALO_MINUTOS="${2:-15}"
SONIDO="/usr/share/sounds/freedesktop/stereo/message.oga"
TODO_FILE="$HOME/.notifier_todos"
TIEMPO_INICIO=$(date +%s)

touch "$TODO_FILE"

function unified_notifier() {
    mapfile -t raw_tasks < "$TODO_FILE"

    checklist_args=()
    for task in "${raw_tasks[@]}"; do
        if [[ "$task" == "[x]"* ]]; then
            checklist_args+=("TRUE" "${task:4}")
        else
            checklist_args+=("FALSE" "$task")
        fi
    done

    HORA_LOCAL=$(date '+%H:%M:%S')
    HORA_BOGOTA=$(TZ=America/Bogota date '+%H:%M:%S')
    TIEMPO_ACTUAL=$(date +%s)
    MINUTOS_TRANSCURRIDOS=$(( (TIEMPO_ACTUAL - TIEMPO_INICIO) / 60 ))

    selection=$(zenity --list         --checklist         --title="🔔 $MENSAJE - $MINUTOS_TRANSCURRIDOS min"         --text="Hora local: $HORA_LOCAL\nHora Bogotá: $HORA_BOGOTA\n\n✔ Marca tareas como hechas\n➕ Agrega nuevas usando el botón\n🗂 Se actualiza al cerrar con 'Actualizar'"         --column="Estado" --column="Tarea"         "${checklist_args[@]}"         --width=600 --height=500         --ok-label="Actualizar"         --cancel-label="Salir"         --extra-button="Agregar")

    code=$?

    if [[ "$selection" == "Agregar" ]]; then
        nueva=$(zenity --entry --title="➕ Nueva tarea" --text="Describe la nueva tarea:")
        [[ -n "$nueva" ]] && echo "$nueva" >> "$TODO_FILE"
        return
    fi

    if [[ "$code" -ne 0 ]]; then
        return
    fi

    IFS="|" read -r -a seleccionadas <<< "$selection"
    new_content=()
    for task in "${raw_tasks[@]}"; do
        base="${task#[x] }"
        if printf "%s\n" "${seleccionadas[@]}" | grep -Fxq "$base"; then
            new_content+=("[x] $base")
        else
            new_content+=("$base")
        fi
    done
    printf "%s\n" "${new_content[@]}" > "$TODO_FILE"
}

if pgrep -f "notificador.sh $INTERVALO_MINUTOS" > /dev/null; then
    echo "⚠ Ya hay un notificador.sh corriendo con ese intervalo. Abortando."
    exit 1
fi

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos."

while true; do
    paplay "$SONIDO" &
    unified_notifier

    MINUTOS_ACTUALES=$(date +%M)
    SEGUNDOS_ACTUALES=$(date +%S)
    RESTO=$((MINUTOS_ACTUALES % INTERVALO_MINUTOS))
    ESPERA=$(( (INTERVALO_MINUTOS - RESTO) * 60 - SEGUNDOS_ACTUALES ))
    [[ "$ESPERA" -le 0 ]] && ESPERA=$((INTERVALO_MINUTOS * 60))

    sleep "$ESPERA"
done
