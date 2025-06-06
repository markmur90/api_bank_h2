#!/bin/bash
# clear
FECHA=$(date '+%Y-%m-%d')
mkdir -p /home/markmur88/notas/logs/$FECHA
FILENAME="voz_$(date '+%H-%M-%S').wav"
echo "🎙 Grabando 60s... (Ctrl+C para cortar antes)"
arecord -d 60 -f cd -t wav /home/markmur88/notas/logs/$FECHA/$FILENAME
# clear
echo "✅ Audio guardado en /home/markmur88/notas/logs/$FECHA/$FILENAME"
