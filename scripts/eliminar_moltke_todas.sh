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
