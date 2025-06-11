#!/bin/bash
FECHA=$(date '+%Y-%m-%d')
HORA=$(date '+%H:%M')
mkdir -p ~/notas/$FECHA
echo "📒 Nota rápida (terminá con Ctrl+D):"
cat >> ~/notas/$FECHA/nota_texto.txt <<EOF
[$HORA]
$(cat)
EOF
echo "✅ Nota guardada en ~/notas/$FECHA/nota_texto.txt"
