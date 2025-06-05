#!/bin/bash

# Lista de IDs disponibles (modificable)
IDS=("01" "02" "03" "salir")

# Menú de acciones
function seleccionar_accion() {
    echo "Seleccioná una acción:"
    select ACCION in "start" "stop" "restart" "status" "logs" "journal" "salir"; do
        case $ACCION in
            start|stop|restart|status|logs|journal)
                break
                ;;
            salir)
                echo "🛑 Cancelado"
                exit 0
                ;;
            *)
                echo "❌ Opción inválida"
                ;;
        esac
    done
}

# Menú de IDs
function seleccionar_ids() {
    echo "Seleccioná los simuladores:"
    select ID in "${IDS[@]}"; do
        [[ $ID == "salir" ]] && exit 0
        if [[ " ${IDS[@]} " =~ " ${ID} " ]]; then
            SELECCION+=("$ID")
            echo "✔️ Agregado: $ID"
        else
            echo "❌ ID inválido"
        fi
        echo "¿Querés agregar otro? (s para sí, enter para continuar)"
        read -r RESP
        [[ $RESP != "s" ]] && break
    done
}

# Inicio
SELECCION=()
seleccionar_accion
seleccionar_ids

# Ejecutar acción sobre IDs seleccionados
for ID in "${SELECCION[@]}"; do
    SERVICIO="simulador_banco_${ID}.service"
    LOG_DIR="/opt/simulador_banco_${ID}/logs"
    echo "🔹 [SIMULADOR $ID] Acción: $ACCION"

    case "$ACCION" in
        start)
            sudo systemctl start "$SERVICIO"
            ;;
        stop)
            sudo systemctl stop "$SERVICIO"
            ;;
        restart)
            sudo systemctl restart "$SERVICIO"
            ;;
        status)
            sudo systemctl status "$SERVICIO"
            ;;
        logs)
            tail -f "$LOG_DIR/simulador_banco.log" "$LOG_DIR/simulador_banco_error.log"
            ;;
        journal)
            sudo journalctl -u "$SERVICIO" --no-pager
            ;;
    esac
done
