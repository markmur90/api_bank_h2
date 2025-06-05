#!/usr/bin/env bash
set +e
exec 2>/dev/null

# # --- logging ---
mkdir -p "$AP_H2_DIR/scripts/gestor_tareas/gestor/logs_notificadores"
LOG_FILE="$AP_H2_DIR/scripts/gestor_tareas/gestor/logs_notificadores/$(basename "$0").log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n🔄 Inicio $(date '+%F %T')"

export DISPLAY=:0.0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

MENSAJE="${1:-⏰ Recordatorio: tiempo transcurrido}"
INTERVALO_MINUTOS="${2:-15}"
SONIDO="/usr/share/sounds/freedesktop/stereo/message.oga"
TODO_FILE="$AP_H2_DIR/scripts/gestor_tareas/gestor/.notifier_todos"
TIEMPO_INICIO=$(date +%s)

# Asegurarse de que exista el archivo de pendientes
touch "$TODO_FILE"

# ------------------------------------------
# Función para gestionar la lista de pendientes
# ------------------------------------------
function manage_todos() {
    while true; do
        mapfile -t raw_tasks < "$TODO_FILE"

        tasks=()
        for line in "${raw_tasks[@]}"; do
            if [[ "$line" =~ ^\[X\] ]]; then
                task_text="${line:4}"
                tasks+=("✔ $(echo "$task_text" | sed 's/^/~/' | sed 's/$/~/' )")  # efecto visual de tachado
            elif [[ "$line" =~ ^\[ \] ]]; then
                tasks+=("• ${line:4}")
            fi
        done

        if [ ${#tasks[@]} -gt 0 ]; then
            task_list=$(printf "%s\n" "${tasks[@]}")
            echo -e "$task_list" | zenity --text-info \
                                          --title="📋 Tareas actuales" \
                                          --width=600 \
                                          --height=400
        fi

        if [ ${#raw_tasks[@]} -eq 0 ]; then
            if zenity --question --title="📋 Lista de pendientes" \
                      --text="No hay tareas pendientes. ¿Deseas agregar una nueva?"; then
                new_task=$(zenity --entry --title="➕ Agregar tarea" --text="Ingresa la descripción:")
                if [ -n "$new_task" ]; then
                    echo "[ ] $new_task" >> "$TODO_FILE"
                fi
                continue
            else
                break
            fi
        fi

        action=$(zenity --list --radiolist \
                        --title="📋 Gestión de pendientes" \
                        --text="¿Qué deseas hacer?" \
                        --column="" --column="Acción" \
                        TRUE "Salir" FALSE "Marcar completadas" FALSE "Agregar nueva" \
                        --width=600 --height=350)
        [ $? -ne 0 ] && break
        [ "$action" == "Salir" ] && break

        if [ "$action" == "Agregar nueva" ]; then
            new_task=$(zenity --entry --title="➕ Agregar tarea" --text="Ingresa la descripción:")
            [ -n "$new_task" ] && echo "[ ] $new_task" >> "$TODO_FILE"
            continue
        fi

        if [ "$action" == "Marcar completadas" ]; then
            checklist_args=()
            for line in "${raw_tasks[@]}"; do
                if [[ "$line" =~ ^\[ \] ]]; then
                    checklist_args+=(FALSE "${line:4}")
                fi
            done

            result=$(zenity --list \
                            --checklist \
                            --title="✔️ Marcar tareas completadas" \
                            --text="Selecciona las tareas completadas:" \
                            --column="" --column="Tarea" \
                            "${checklist_args[@]}" \
                            --width=500 \
                            --height=800 \
                            --ok-label="Marcar como hechas" \
                            --cancel-label="Volver")
            [ $? -ne 0 ] && continue
            [ -z "$result" ] && continue

            IFS="|" read -r -a done_tasks <<< "$result"
            tmpfile=$(mktemp)
            while IFS= read -r line; do
                updated=false
                for done in "${done_tasks[@]}"; do
                    if [[ "$line" == "[ ] $done" ]]; then
                        echo "[X] $done" >> "$tmpfile"
                        updated=true
                        break
                    fi
                done
                [ "$updated" = false ] && echo "$line" >> "$tmpfile"
            done < "$TODO_FILE"
            mv "$tmpfile" "$TODO_FILE"
            continue
        fi
    done
}


TIEMPO_INICIO=$(date +%s)

# Mensaje inicial en consola
echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

# ------------------------------------------
# Bucle principal de notificaciones
# ------------------------------------------

# # Evitar duplicados
# if pgrep -f "notificador.sh 5" > /dev/null; then
#   echo "⚠ Ya hay un notificador.sh corriendo con intervalo 5 minutos. Abortando."
#   exit 1
# fi


while true; do
    # 1) Mostrar notificación visual + sonido
    HORA_LOCAL=$(date '+%H:%M:%S')
    HORA_BOGOTA=$(TZ=America/Bogota date '+%H:%M:%S')

    # Enviar notificación visual con zenity y sonido en paralelo
    TIEMPO_ACTUAL=$(date +%s)
    MINUTOS_TRANSCURRIDOS=$(( (TIEMPO_ACTUAL - TIEMPO_INICIO) / 60 ))

    (
    zenity --info \
        --title="🔔 Tiempo transcurrido: $MINUTOS_TRANSCURRIDOS minutos" \
        --text="$MENSAJE\nHora local: $HORA_LOCAL\nHora Bogotá: $HORA_BOGOTA" \
        --timeout=3
    ) &
    paplay "$SONIDO" &

    # 2) Si el usuario cierra o ignora la notificación (exit != 0), terminar
    if [[ $? -ne 0 ]]; then
        echo "⏹ Notificación ignorada, continuo...."
    fi

    # 3) Gestionar la lista de pendientes después de la notificación
    manage_todos

    # 4) Calcular segundos hasta el siguiente múltiplo de INTERVALO_MINUTOS
    MINUTOS_ACTUALES=$(date +%M)
    SEGUNDOS_ACTUALES=$(date +%S)
    RESTO=$((MINUTOS_ACTUALES % INTERVALO_MINUTOS))
    ESPERA=$(( (INTERVALO_MINUTOS - RESTO) * 60 - SEGUNDOS_ACTUALES ))
    if [ "$ESPERA" -le 0 ]; then
        ESPERA=$((INTERVALO_MINUTOS * 60))
    fi

    # 5) Dormir hasta el próximo disparo
    sleep "$ESPERA"
done
