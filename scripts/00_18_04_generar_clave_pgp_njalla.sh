#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/00_18_04_generar_clave_pgp_njalla/00_18_04_generar_clave_pgp_njalla.log"
PROCESS_LOG="$SCRIPT_DIR/logs/00_18_04_generar_clave_pgp_njalla/process_00_18_04_generar_clave_pgp_njalla.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/00_18_04_generar_clave_pgp_njalla_.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PROCESS_LOG")"
mkdir -p "$(dirname "$LOG_DEPLOY")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR



#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

#!/bin/bash

set -e

echo "🔐 Generando clave PGP protegida para Njalla..."

# ======================
# CONFIGURACIÓN
# ======================
NOMBRE="James Von Moltke"
EMAIL="j.moltke@db.com"
COMENTARIO="PGP"
CLAVE_SALIDA="jmoltke"
GPG_DIR="$HOME/.gnupg"

# ======================
# COMPROBAR DEPENDENCIAS
# ======================
if ! command -v gpg > /dev/null; then
    echo "❌ GnuPG no está instalado. Instalalo con: sudo apt install gnupg"
    exit 1
fi

# ======================
# GENERAR LA CLAVE CON CONTRASEÑA
# ======================
echo
echo "📝 A continuación se abrirá el asistente de GPG para generar una clave protegida con contraseña."
echo "   Usá estos datos:"
echo "   - Nombre  : $NOMBRE"
echo "   - Email   : $EMAIL"
echo "   - Coment. : $COMENTARIO"
echo "   - Tamaño  : 4096"
echo "   - Expira  : 0 (sin expiración)"
echo

gpg --full-generate-key

# ======================
# EXPORTAR CLAVE PÚBLICA
# ======================
gpg --armor --output "$CLAVE_SALIDA"_public.asc --export "$EMAIL"
echo "✅ Clave pública exportada a: $CLAVE_SALIDA"_public.asc

# ======================
# EXPORTAR CLAVE PRIVADA
# ======================
gpg --armor --output "$CLAVE_SALIDA"_private.asc --export-secret-keys "$EMAIL"
chmod 600 "$CLAVE_SALIDA"_private.asc
echo "✅ Clave privada exportada a: "$CLAVE_SALIDA"_private.asc (¡GUARDALA EN UN USB CIFRADO!)"

# ======================
# VERIFICACIÓN
# ======================
echo
echo "📋 Resumen de la clave generada:"
gpg --list-keys "$EMAIL"

# ======================
# ABRIR CLAVE EN EDITOR
# ======================
echo
echo "📝 Abriendo la clave pública en tu editor predeterminado..."
xdg-open "$CLAVE_SALIDA"_public.asc &

echo
echo "📩 Pegá el contenido en Njalla (PGP Key Field) para que te cifren los correos."