#!/bin/bash
FECHA=$(date '+%Y-%m-%d')
DIR_TXT="$HOME/notas/texto"
DIR_AUD="$HOME/notas/audio/$FECHA"
echo "📆 Resumen del día: $FECHA"
echo "📝 Notas de texto:"
[ -f "$DIR_TXT/$FECHA.txt" ] && cat "$DIR_TXT/$FECHA.txt" || echo "Ninguna"
echo -e "\n🎤 Audios grabados:"
[ -d "$DIR_AUD" ] && ls "$DIR_AUD"/voz_*.wav 2>/dev/null || echo "Ninguno"
