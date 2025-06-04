#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$HOME/api_bank_h2/scripts"
LOG_DIR="$SCRIPT_DIR/.logs"

NOTIF1="$SCRIPT_DIR/notificador.sh"
NOTIF2="$SCRIPT_DIR/notificador_30.sh"

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
