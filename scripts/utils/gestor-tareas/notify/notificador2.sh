#!/usr/bin/env bash
set +e
exec 2>/dev/null

#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
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

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

LOG_DIR="$GT_NT_DIR/logs_notificadores"

NOTIF1="$GT_NT_DIR/notificador.sh"
NOTIF2="$GT_NT_DIR/notificador_30.sh"

# # --- logging ---
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

    selection=$(zenity --list --checklist \
        --title="🔔 $MENSAJE - $MINUTOS_TRANSCURRIDOS min" \
        --text="Hora local: $HORA_LOCAL\nHora Bogotá: $HORA_BOGOTA\n\n✔ Marca tareas como hechas\n➕ Agrega nuevas usando el botón\n🗂 Se actualiza al cerrar con 'Actualizar'" \
        --column="Estado" --column="Tarea" \
        "${checklist_args[@]}" \
        --width=500 --height=800 \
        --ok-label="Actualizar" \
        --cancel-label="Salir" \
        --extra-button="Agregar")

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
        base="${task#[x]}"
        base="${base## }"
        if printf "%s\n" "${seleccionadas[@]}" | grep -Fxq "$base"; then
            new_content+=("[x] $base")
        else
            new_content+=("$base")
        fi
    done
    printf "%s\n" "${new_content[@]}" > "$TODO_FILE"
}

# if pgrep -f "notificador.sh $INTERVALO_MINUTOS" > /dev/null; then
#     echo "⚠ Ya hay un notificador.sh corriendo con ese intervalo. Abortando."
#     exit 1
# fi

TIEMPO_INICIO=$(date +%s)


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
