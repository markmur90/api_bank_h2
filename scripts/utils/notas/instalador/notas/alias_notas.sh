#!/usr/bin/env bash
clear
# Detectar el directorio actual del script
INSTALL_DIR="/home/markmur88/notas"
# INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Alias para ejecutar scripts desde el directorio actual
alias alerta_horaria="bash \"$INSTALL_DIR/alerta_horaria.sh\""
alias nota_texto="bash \"$INSTALL_DIR/nota_texto.sh\""
alias nota_voz="bash \"$INSTALL_DIR/nota_voz.sh\""
alias resumen_dia="bash \"$INSTALL_DIR/resumen_dia.sh\""
alias resumen_proyecto="bash \"$INSTALL_DIR/resumen_proyecto.sh\""
alias resumen_audio="bash \"$INSTALL_DIR/resumen_audio.sh\""
alias backup_now="bash \"$INSTALL_DIR/daily_backup.sh\""
alias sync_backup="bash \"$INSTALL_DIR/backup_and_sync.sh\""

# Alias de menú y ayuda
alias notas='clear; 
echo "📚 GUÍA COMPLETA DE AYUDA DISPONIBLE";
echo "-------------------------------------";
echo "alerta_horaria       → Ejecuta alerta horaria con logs y Telegram";
echo "nota_texto           → Crea una nueva nota de texto";
echo "nota_voz             → Graba una nota de voz";
echo "resumen_dia          → Genera resumen de notas diarias";
echo "resumen_proyecto     → Muestra resumen filtrado por proyecto";
echo "resumen_audio        → Convierte resumen a audio";
echo "backup_now           → Ejecuta backup manual";
echo "sync_backup          → Sincroniza backups y notas";
'
