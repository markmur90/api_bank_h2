#!/bin/bash
FECHA=$(date '+%Y-%m-%d')
HORA=$(date '+%H-%M-%S')
DIR="/home/markmur88/notas/audio/$FECHA"
mkdir -p "$DIR"
FILENAME="voz_$HORA.wav"
echo "🎙 Grabando 60s... (Ctrl+C para cortar antes)"
arecord -d 60 -f cd -t wav "$DIR/$FILENAME"
echo "✅ Audio guardado en $DIR/$FILENAME"
