#!/bin/bash

# === VARIABLES ===
SCRIPT_DIR="/home/markmur88/scripts_notas_proyecto"
CRON_TEMP="/tmp/cron_instalador.txt"
ZIP_PATH="/home/markmur88/Downloads/scripts_notas_proyecto_completo.zip"

# === EXTRAER ZIP ===
echo "📦 Extrayendo scripts..."
mkdir -p "$SCRIPT_DIR"
unzip -o "$ZIP_PATH" -d "$SCRIPT_DIR"

# === PERMISOS ===
chmod +x "$SCRIPT_DIR"/*.sh

# === CONFIGURAR CRONTAB ===
echo "🛠 Configurando tareas cron..."

crontab -l 2>/dev/null > "$CRON_TEMP"

# Resumen diario 22:00
grep -q "resumen_diario.sh" "$CRON_TEMP" || echo "0 22 * * * $SCRIPT_DIR/resumen_diario.sh >> $SCRIPT_DIR/logs/resumen.log 2>&1" >> "$CRON_TEMP"

# Alerta horaria
grep -q "alerta_horaria.sh" "$CRON_TEMP" || echo "0 * * * * $SCRIPT_DIR/alerta_horaria.sh >> $SCRIPT_DIR/logs/alerta.log 2>&1" >> "$CRON_TEMP"

# Aplicar nuevo crontab
crontab "$CRON_TEMP"
rm "$CRON_TEMP"

# === DIRECTORIOS DE APOYO ===
mkdir -p "$SCRIPT_DIR/logs"
mkdir -p "$SCRIPT_DIR/voice_notes"
mkdir -p "$SCRIPT_DIR/text_notes"
mkdir -p "$SCRIPT_DIR/backup"

echo "✅ Instalación completada. Los scripts están en: $SCRIPT_DIR"
