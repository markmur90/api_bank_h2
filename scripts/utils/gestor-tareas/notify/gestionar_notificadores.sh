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

mkdir -p "$LOG_DIR"

echo "🔧 ¿Qué querés hacer?"
select OPCION in "Iniciar notificadores" "Detener notificadores" "Reiniciar notificadores" "Ver logs" "Salir"; do
    case $OPCION in
        "Iniciar notificadores")
            read -p "⏱️ Intervalo para tareas (def 15): " INTERVALO1
            read -p "⏱️ Intervalo para VPS Njalla (def 30): " INTERVALO2
            INTERVALO1="${INTERVALO1:-15}"
            INTERVALO2="${INTERVALO2:-30}"

            nohup bash "$NOTIF1" "" "$INTERVALO1" > "$LOG_DIR/notificador.log" 2>&1 &
            nohup bash "$NOTIF2" "" "$INTERVALO2" > "$LOG_DIR/notificador_30.log" 2>&1 &

            echo "✅ Iniciados con $INTERVALO1 min (tareas) y $INTERVALO2 min (VPS)"
            break
            ;;
        "Detener notificadores")
            pkill -f "$NOTIF1" && echo "🛑 Notificador de tareas detenido"
            pkill -f "$NOTIF2" && echo "🛑 Notificador VPS detenido"
            break
            ;;
        "Reiniciar notificadores")
            pkill -f "$NOTIF1" 2>/dev/null || true
            pkill -f "$NOTIF2" 2>/dev/null || true
            echo "🔁 Notificadores detenidos. Ahora se reiniciarán..."
            sleep 1
            read -p "⏱️ Intervalo para tareas (def 15): " INTERVALO1
            read -p "⏱️ Intervalo para VPS Njalla (def 30): " INTERVALO2
            INTERVALO1="${INTERVALO1:-15}"
            INTERVALO2="${INTERVALO2:-30}"

            nohup bash "$NOTIF1" "" "$INTERVALO1" > "$LOG_DIR/notificador.log" 2>&1 &
            nohup bash "$NOTIF2" "" "$INTERVALO2" > "$LOG_DIR/notificador_30.log" 2>&1 &

            echo "✅ Reiniciados con $INTERVALO1 min (tareas) y $INTERVALO2 min (VPS)"
            break
            ;;
        "Ver logs")
            echo "📄 Logs disponibles en: $LOG_DIR"
            ls -lh "$LOG_DIR"
            break
            ;;
        "Salir")
            echo "👋 Cancelado."
            break
            ;;
        *)
            echo "❓ Opción no válida"
            ;;
    esac
done
