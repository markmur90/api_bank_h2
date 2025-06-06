#!/bin/bash
clear
FECHA=$(date '+%Y-%m-%d')
HORA=$(date '+%H:%M')
mkdir -p /home/markmur88/notas/logs/$FECHA
echo "📒 Nota rápida (terminá con Ctrl+D):"
cat >> /home/markmur88/notas/logs/$FECHA/nota_texto.txt <<EOF
[$HORA]
$(cat)
EOF

# clear
echo "✅ Nota guardada en /home/markmur88/notas/logs/$FECHA/nota_texto.txt"
