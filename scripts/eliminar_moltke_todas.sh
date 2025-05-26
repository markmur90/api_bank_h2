#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

#!/bin/bash

set -e

CLAVES=(
    DE81B9C38A53D63678BC1EE78AFA09EF846D931B
    F4C2C9C320F939A19DC957510745CB1654D01C4F
    CE952F5C3F9E1385FFD080CEF7157B6D4AEC2004
)

echo "🗑️ Eliminando claves PGP asociadas a j.moltke@db.com..."

for FPR in "${CLAVES[@]}"; do
    echo "🔒 Eliminando clave secreta: $FPR"
    gpg --batch --yes --delete-secret-key "$FPR"

    echo "📬 Eliminando clave pública: $FPR"
    gpg --batch --yes --delete-key "$FPR"
done

echo "🧹 Eliminando archivos exportados..."
rm -f bar1588623_public.asc
rm -f bar1588623_private.asc
rm -f bar1588623_private.asc.gpg
rm -f pgp_njalla*.asc

echo "✅ Todas las claves y archivos han sido eliminados completamente."
