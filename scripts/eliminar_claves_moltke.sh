#!/bin/bash

set -e

EMAIL="j.moltke@db.com"
CLAVE_SALIDA="bar1588623"

echo "🔍 Buscando huellas digitales asociadas a: $EMAIL"

# Buscar huellas de claves privadas
FPRIVS=$(gpg --list-secret-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}')

# Eliminar claves privadas (por fingerprint)
for fpr in $FPRIVS; do
    echo "🔒 Eliminando clave secreta $fpr"
    gpg --batch --yes --delete-secret-key "$fpr"
done

# Buscar huellas de claves públicas
FPUBS=$(gpg --list-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}')

# Eliminar claves públicas (por fingerprint)
for fpr in $FPUBS; do
    echo "📬 Eliminando clave pública $fpr"
    gpg --batch --yes --delete-key "$fpr"
done

# Borrar archivos exportados
echo "🧹 Eliminando archivos exportados..."
rm -f "$CLAVE_SALIDA"_public.asc
rm -f "$CLAVE_SALIDA"_private.asc
rm -f "$CLAVE_SALIDA"_private.asc.gpg

echo "✅ Todas las claves y archivos relacionados con '$EMAIL' han sido eliminados por completo."
