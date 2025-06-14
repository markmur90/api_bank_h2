#!/bin/bash
echo "📦 Resumen total del proyecto"
echo "📝 Notas acumuladas:"
find "/home/markmur88/notas/texto" -type f -name "*.txt" -exec echo "🗒 {}" \; -exec cat {} \;
echo -e "\n🎤 Audios acumulados:"
find "/home/markmur88/notas/audio" -type f -name "voz_*.wav"
