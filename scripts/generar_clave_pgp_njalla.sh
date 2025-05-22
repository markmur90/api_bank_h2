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
