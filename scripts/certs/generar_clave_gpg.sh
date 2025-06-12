#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

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
