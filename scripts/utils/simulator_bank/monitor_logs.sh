#!/bin/bash
echo "📡 Monitoreando logs del Simulador Banco..."
echo "Presiona Ctrl+C para salir."
tail -f /opt/simulador_banco/logs/simulador_banco.log /opt/simulador_banco/logs/simulador_banco_error.log
