#!/usr/bin/env bash
set +e

# ------------------------------------------
# Configuración inicial
# ------------------------------------------
export DISPLAY=:0.0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

MENSAJE="${1:-⏰ Recordatorio: tiempo transcurrido}"
INTERVALO_MINUTOS="${2:-15}"
SONIDO="/usr/share/sounds/freedesktop/stereo/message.oga"
TODO_FILE="$HOME/.notifier_todos"
TIEMPO_INICIO=$(date +%s)

# Asegurarse de que exista el archivo de pendientes
touch "$TODO_FILE"

# ------------------------------------------
# Función para gestionar la lista de pendientes
# ------------------------------------------
function manage_todos() {
    while true; do
        mapfile -t raw_tasks < "$TODO_FILE"
        [ ${#raw_tasks[@]} -eq 0 ] && zenity --info --text="🎉 No hay tareas registradas." --timeout=2 && break

        # Convertir a formato visual
        gui_tasks=()
        for t in "${raw_tasks[@]}"; do
            [[ "$t" == "[x]"* ]] && gui_tasks+=("[✔] ${t:4}") || gui_tasks+=("[ ] $t")
        done

        # Mostrar la lista
        SELECCION=$(zenity --list --title="📋 Tareas activas" \
            --text="Seleccioná una para marcar / desmarcar / eliminar:" \
            --column="Tarea" "${gui_tasks[@]}" \
            --height=500 --width=400)

        [ -z "$SELECCION" ] && break

        # Reconstruir texto real del archivo
        tarea_real="${SELECCION#[✔] }"
        tarea_real="${tarea_real#[ ] }"

        grep -q "^\[x\] $tarea_real$" "$TODO_FILE"
        is_done=$?

        if [[ "$is_done" -eq 0 ]]; then
            ACCION=$(zenity --list --title="⏱ Tarea ejecutada" --text="¿Qué hacer con:\n$tarea_real" \
                --column="Acción" --column="Descripción" \
                "❌ Eliminar" "Quitar completamente esta tarea" \
                "↩ Desmarcar" "Volverla a estado pendiente" \
                --height=200 --width=400)

            case "$ACCION" in
              "❌ Eliminar") sed -i "\|^\[x\] $tarea_real$|d" "$TODO_FILE" ;;
              "↩ Desmarcar") sed -i "s|^\[x\] $tarea_real$|$tarea_real|" "$TODO_FILE" ;;
            esac
        else
            ACCION=$(zenity --question --text="¿Marcar como hecha?\n\n$tarea_real" --ok-label="Sí" --cancel-label="No" && echo "yes" || echo "no")
            [[ "$ACCION" == "yes" ]] && sed -i "s|^$tarea_real$|[x] $tarea_real|" "$TODO_FILE"
        fi
    done
}



TIEMPO_INICIO=$(date +%s)

# Mensaje inicial en consola
echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

# ------------------------------------------
# Bucle principal de notificaciones
# ------------------------------------------

# Evitar duplicados
if pgrep -f "notificador.sh 5" > /dev/null; then
  echo "⚠ Ya hay un notificador.sh corriendo con intervalo 5 minutos. Abortando."
  exit 1
fi


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
