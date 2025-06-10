#!/bin/bash
FECHA=$(date '+%Y-%m-%d')
mkdir -p ~/notas/$FECHA
FILENAME="voz_$(date '+%H-%M-%S').wav"
echo "🎙 Grabando 60s... (Ctrl+C para cortar antes)"
arecord -d 60 -f cd -t wav ~/notas/$FECHA/$FILENAME
echo "✅ Audio guardado en ~/notas/$FECHA/$FILENAME"
