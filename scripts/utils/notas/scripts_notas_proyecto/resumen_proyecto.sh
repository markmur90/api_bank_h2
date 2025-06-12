#!/bin/bash
echo "📦 Resumen total del proyecto (notas acumuladas)"
find ~/notas -type f -name "nota_texto.txt" -exec echo "📝" {} \; -exec cat {} \;
echo -e "\n🎤 Audios grabados:"
find ~/notas -type f -name "voz_*.wav"
