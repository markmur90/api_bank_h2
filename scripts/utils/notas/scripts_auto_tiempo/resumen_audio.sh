#!/bin/bash

# === CONFIGURACIÓN ===
DIR_LOG="/home/markmur88/logs_tiempo"
ARCHIVO_RESUMEN_DIARIO="$DIR_LOG/resumen_diario.log"
ARCHIVO_RESUMEN_PROYECTO="$DIR_LOG/resumen_proyecto.log"

# === GENERAR RESUMEN DE AUDIO ===
RESUMEN_DIARIO=$(cat "$ARCHIVO_RESUMEN_DIARIO")
RESUMEN_PROYECTO=$(cat "$ARCHIVO_RESUMEN_PROYECTO")

espeak "Resumen del día: $RESUMEN_DIARIO. Resumen del proyecto: $RESUMEN_PROYECTO"
