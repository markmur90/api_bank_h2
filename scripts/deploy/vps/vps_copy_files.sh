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

set -euo pipefail

USER="markmur88"
IP="80.78.30.242"

# 1) Verificar que se ejecute exclusivamente como “markmur88”
if [ "$(whoami)" != "$USER" ]; then
    echo "❌ Este script debe ser ejecutado por el usuario: $USER"
    exit 1
fi

# 2) Rutas SSH
HOME_DIR="/home/$USER"
KEY="/home/markmur88_DIR/.ssh/vps_njalla_nueva"
REMOTE_BASE="/home/markmur88_DIR"

# 3) Preparar directorio de logs
LOG_DIR="/home/markmur88_DIR/transfer_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/download_$(date '+%Y%m%d_%H%M%S').log"

echo "📁 INICIO: Selecciona carpeta ORIGEN en VPS ($IP)."

# --- NAVEGACIÓN REMOTA ---
current_dir_remote="$REMOTE_BASE"
while true; do
    echo
    echo "🖧 Remoto: $current_dir_remote"
    echo "   0) [Elegir ESTE: $(basename "$current_dir_remote")]"
    idx=1
    if [ "$current_dir_remote" != "$REMOTE_BASE" ]; then
        echo "   $idx) ../"
        ((idx++))
    fi
    mapfile -t remote_dirs < <(
        ssh -i "$KEY" -p 22 "$USER@$IP" \
        "cd \"$current_dir_remote\" && \
         find . -maxdepth 1 -mindepth 1 -type d -printf '%P\n' | sort"
    )
    for d in "${remote_dirs[@]}"; do
        echo "   $idx) ${d}/"
        ((idx++))
    done

    read -rp "➡ Número (0=elegir, otro=navegar): " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || { echo "   ❌ Debe ser número"; continue; }
    (( choice > idx-1 )) && { echo "   ❌ Fuera de rango"; continue; }

    if (( choice == 0 )); then
        REMOTE_SOURCE="$current_dir_remote"
        break
    fi

    # navegar
    if (( choice == 1 && current_dir_remote != REMOTE_BASE )); then
        current_dir_remote="$(dirname "$current_dir_remote")"
    else
        # ajustar índice según si mostramos ../
        offset=$(( current_dir_remote != REMOTE_BASE ? 2 : 1 ))
        sel=$(( choice - offset ))
        current_dir_remote="$current_dir_remote/${remote_dirs[$sel]}"
    fi
done

echo "✅ Carpeta remota: $REMOTE_SOURCE"
echo
echo "📁 Ahora: Selecciona carpeta DESTINO local."

# --- NAVEGACIÓN LOCAL ---
current_dir_local="/home/markmur88_DIR"
while true; do
    echo
    echo "🗂 Local: $current_dir_local"
    echo "   0) [Elegir ESTE: $(basename "$current_dir_local")]"
    idx=1
    if [ "$current_dir_local" != "/home/markmur88_DIR" ]; then
        echo "   $idx) ../"
        ((idx++))
    fi
    mapfile -t local_dirs < <(find "$current_dir_local" -maxdepth 1 -mindepth 1 -type d | sort)
    for d in "${local_dirs[@]}"; do
        echo "   $idx) $(basename "$d")/"
        ((idx++))
    done

    read -rp "➡ Número (0=elegir, otro=navegar): " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || { echo "   ❌ Debe ser número"; continue; }
    (( choice > idx-1 )) && { echo "   ❌ Fuera de rango"; continue; }

    if (( choice == 0 )); then
        LOCAL_DEST="$current_dir_local"
        break
    fi

    if (( choice == 1 && current_dir_local != HOME_DIR )); then
        current_dir_local="$(dirname "$current_dir_local")"
    else
        offset=$(( current_dir_local != HOME_DIR ? 2 : 1 ))
        sel=$(( choice - offset ))
        current_dir_local="${local_dirs[$sel]}"
    fi
done

echo "✅ Carpeta local: $LOCAL_DEST"
echo
echo "🚀 Iniciando rsync..."

# --- EJECUTAR RSYNC para transferir ---
{
    echo "=== DOWNLOAD $(date '+%Y-%m-%d %H:%M:%S') ==="
    echo " Origen remoto: $REMOTE_SOURCE"
    echo " Destino local: $LOCAL_DEST"
    rsync -aHvz \
        -e "ssh -i \"$KEY\" -p 22" \
        "$USER@$IP:$REMOTE_SOURCE" "$LOCAL_DEST"
    echo "✅ Transferencia completada."
} | tee "$LOG_FILE"
