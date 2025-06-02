#!/usr/bin/env bash
set -euo pipefail

NOMBRE="Mark Mur"
EMAIL="jmoltke@protonmail.com"
COMENTARIO="clave despliegue"
KEY_TYPE="RSA"
KEY_LENGTH="4096"
EXPIRA="0"
PASS="Ptf8454Jd55"

# 🔍 Verifica si ya existe una clave
if gpg --list-keys "$EMAIL" &>/dev/null; then
    echo "⚠️ Ya existe una clave para $EMAIL. Abortando para evitar duplicados."
    exit 1
fi

# 🧱 Crear archivo temporal con parámetros
PARAMS=$(mktemp)
cat > "$PARAMS" <<EOF
%echo Generando nueva clave GPG...
Key-Type: $KEY_TYPE
Key-Length: $KEY_LENGTH
Subkey-Type: $KEY_TYPE
Subkey-Length: $KEY_LENGTH
Name-Real: $NOMBRE
Name-Email: $EMAIL
Name-Comment: $COMENTARIO
Expire-Date: $EXPIRA
Passphrase: $PASS
%commit
%echo Clave generada
EOF

# 🛠️ Generar clave
gpg --batch --generate-key "$PARAMS"
rm "$PARAMS"

# 📂 Crear carpeta si no existe
mkdir -p ./gpg_keys

# 🛡️ Exportar clave privada
gpg --armor --output ./gpg_keys/jmoltke_private.asc --export-secret-keys "$EMAIL"

# 🔓 Exportar clave pública
gpg --armor --output ./gpg_keys/jmoltke_public.asc --export "$EMAIL"

# 🧬 Guardar fingerprint
FPR=$(gpg --with-colons --list-keys "$EMAIL" | awk -F: '/^fpr:/ {print $10; exit}')
echo "$EMAIL → $FPR" > ./gpg_keys/fingerprint.txt

echo "✅ Claves exportadas en ./gpg_keys/"
