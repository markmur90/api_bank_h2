#!/bin/bash
echo "📡 Monitoreando logs del Simulador Banco..."
echo "Presiona Ctrl+C para salir."
tail -f /var/log/simulador_banco.log /var/log/simulador_banco_error.log
