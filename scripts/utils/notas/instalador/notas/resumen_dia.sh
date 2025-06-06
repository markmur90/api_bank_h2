#!/bin/bash
clear
FECHA=$(date '+%Y-%m-%d')
DIR=/home/markmur88/notas/logs/$FECHA
echo "📆 Resumen del día: $FECHA"
echo "📝 Notas de texto:"
[ -f "$DIR/nota_texto.txt" ] && cat "$DIR/nota_texto.txt" || echo "Ninguna"
echo -e "\n🎤 Archivos de voz:"
[ -d "$DIR" ] && ls $DIR/voz_*.wav 2>/dev/null || echo "Ninguno"
