#!/bin/bash

# Script para gestionar agentes ElizaOS
# Uso: ./gestionar_agentes.sh [comando] [nombre_agente]

COMMAND=${1:-"list"}
AGENT_NAME=${2:-""}

echo "🤖 Gestión de Agentes ElizaOS"
echo "Comando: $COMMAND"
if [ ! -z "$AGENT_NAME" ]; then
    echo "Agente: $AGENT_NAME"
fi
echo ""

case $COMMAND in
    "list")
        echo "📋 Agentes Activos:"
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 list"
        ;;
    
    "status")
        if [ -z "$AGENT_NAME" ]; then
            echo "❌ Error: Debes especificar el nombre del agente"
            echo "Uso: ./gestionar_agentes.sh status [nombre_agente]"
            exit 1
        fi
        echo "📊 Estado del agente $AGENT_NAME:"
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 show $AGENT_NAME"
        ;;
    
    "logs")
        if [ -z "$AGENT_NAME" ]; then
            echo "❌ Error: Debes especificar el nombre del agente"
            echo "Uso: ./gestionar_agentes.sh logs [nombre_agente] [líneas]"
            exit 1
        fi
        LINES=${3:-"20"}
        echo "📋 Logs del agente $AGENT_NAME (últimas $LINES líneas):"
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 logs $AGENT_NAME --lines $LINES"
        ;;
    
    "restart")
        if [ -z "$AGENT_NAME" ]; then
            echo "❌ Error: Debes especificar el nombre del agente"
            echo "Uso: ./gestionar_agentes.sh restart [nombre_agente]"
            exit 1
        fi
        echo "🔄 Reiniciando agente $AGENT_NAME..."
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 restart $AGENT_NAME"
        echo "✅ Agente $AGENT_NAME reiniciado"
        ;;
    
    "stop")
        if [ -z "$AGENT_NAME" ]; then
            echo "❌ Error: Debes especificar el nombre del agente"
            echo "Uso: ./gestionar_agentes.sh stop [nombre_agente]"
            exit 1
        fi
        echo "🛑 Deteniendo agente $AGENT_NAME..."
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 stop $AGENT_NAME"
        echo "✅ Agente $AGENT_NAME detenido"
        ;;
    
    "delete")
        if [ -z "$AGENT_NAME" ]; then
            echo "❌ Error: Debes especificar el nombre del agente"
            echo "Uso: ./gestionar_agentes.sh delete [nombre_agente]"
            exit 1
        fi
        echo "🗑️ Eliminando agente $AGENT_NAME..."
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 delete $AGENT_NAME"
        echo "✅ Agente $AGENT_NAME eliminado"
        ;;
    
    "monitor")
        echo "📊 Monitor de agentes (Ctrl+C para salir):"
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 monit"
        ;;
    
    "ports")
        echo "🌐 Puertos en uso:"
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "netstat -tlnp | grep -E ':(918[2-7])'"
        ;;
    
    "clean")
        echo "🧹 Limpiando agentes detenidos..."
        ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 "pm2 delete all 2>/dev/null || true"
        echo "✅ Todos los agentes eliminados"
        ;;
    
    "help")
        echo "📖 Comandos disponibles:"
        echo "  list                    - Listar todos los agentes activos"
        echo "  status [agente]         - Mostrar estado de un agente específico"
        echo "  logs [agente] [líneas]  - Mostrar logs de un agente"
        echo "  restart [agente]        - Reiniciar un agente"
        echo "  stop [agente]           - Detener un agente"
        echo "  delete [agente]         - Eliminar un agente"
        echo "  monitor                 - Abrir monitor de agentes"
        echo "  ports                   - Mostrar puertos en uso"
        echo "  clean                   - Eliminar todos los agentes"
        echo "  help                    - Mostrar esta ayuda"
        echo ""
        echo "Ejemplos:"
        echo "  ./gestionar_agentes.sh list"
        echo "  ./gestionar_agentes.sh status mi-agente"
        echo "  ./gestionar_agentes.sh logs mi-agente 50"
        echo "  ./gestionar_agentes.sh restart mi-agente"
        ;;
    
    *)
        echo "❌ Comando no reconocido: $COMMAND"
        echo "Usa './gestionar_agentes.sh help' para ver los comandos disponibles"
        exit 1
        ;;
esac 