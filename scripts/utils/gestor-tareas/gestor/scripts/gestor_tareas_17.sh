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
TODO_FILE="$GE_LG_DIR/$SCRIPT_NAME"
mkdir -p "$TODO_FILE"

MENSAJE="${1:-⏰ Recordatorio: tiempo transcurrido}"
INTERVALO_MINUTOS="${2:-15}"
SONIDO="/usr/share/sounds/freedesktop/stereo/message.oga"

# Asegurar existencia del archivo
mkdir -p "$(dirname "$TODO_FILE")"
touch "$TODO_FILE"

TIEMPO_INICIO=$(date +%s)

# ------------------------------------------
# Función para gestionar la lista de pendientes
# ------------------------------------------
function manage_todos() {
    while true; do
        raw_tasks=()
        if [ -s "$TODO_FILE" ]; then
            mapfile -t raw_tasks < "$TODO_FILE"
        fi

        tasks=()
        for line in "${raw_tasks[@]}"; do
            [[ -z "$line" ]] && continue
            if [[ "$line" =~ ^\[X\] ]]; then
                task_text="${line:4}"
                tasks+=("✔ $task_text")
            elif [[ "$line" =~ ^\[ \] ]]; then
                tasks+=("• ${line:4}")
            fi
        done

        if [ ${#tasks[@]} -gt 0 ]; then
            task_list=$(printf "%s\n" "${tasks[@]}")
            echo -e "$task_list" | zenity --text-info \
                                          --title="📋 Tareas actuales" \
                                          --width=600 --height=400
        fi

        if [ ${#raw_tasks[@]} -eq 0 ]; then
            if zenity --question --title="📋 Lista de pendientes" \
                      --text="No hay tareas pendientes. ¿Deseas agregar una nueva?"; then
                new_task=$(zenity --entry --title="➕ Agregar tarea" --text="Ingresa la descripción:")
                [ -n "$new_task" ] && echo "[ ] $new_task" >> "$TODO_FILE"
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
                            --width=700 --height=500 \
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


# ------------------------------------------
# Bucle principal de notificaciones
# ------------------------------------------
echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

while true; do
    HORA_LOCAL=$(date '+%H:%M:%S')
    HORA_BOGOTA=$(TZ=America/Bogota date '+%H:%M:%S')
    TIEMPO_ACTUAL=$(date +%s)
    MINUTOS_TRANSCURRIDOS=$(( (TIEMPO_ACTUAL - TIEMPO_INICIO) / 60 ))

    (
    zenity --info \
        --title="🔔 Tiempo transcurrido: $MINUTOS_TRANSCURRIDOS minutos" \
        --text="$MENSAJE\nHora local: $HORA_LOCAL\nHora Bogotá: $HORA_BOGOTA" \
        --timeout=3
    ) &
    paplay "$SONIDO" &

    if [[ $? -ne 0 ]]; then
        echo "⏹ Notificación ignorada, continuo...."
    fi

    manage_todos

    MINUTOS_ACTUALES=$(date +%M)
    SEGUNDOS_ACTUALES=$(date +%S)
    RESTO=$((MINUTOS_ACTUALES % INTERVALO_MINUTOS))
    ESPERA=$(( (INTERVALO_MINUTOS - RESTO) * 60 - SEGUNDOS_ACTUALES ))
    [ "$ESPERA" -le 0 ] && ESPERA=$((INTERVALO_MINUTOS * 60))

    sleep "$ESPERA"
done
