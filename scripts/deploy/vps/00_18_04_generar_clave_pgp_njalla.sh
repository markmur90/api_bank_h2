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
# ⚠️ Detectar y cambiar a usuario no-root si es necesario


if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
    echo "🧍 Ejecutando como root. Cambiando a usuario 'markmur88'..."
    exec sudo -i -u markmur88 "$0" "$@"
    exit 0
fi

# Auto-reinvoca con bash si no está corriendo con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Función para autolimpieza de huella SSH
verificar_huella_ssh() {
    local host="$1"
    echo "🔍 Verificando huella SSH para $host..."
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$host" "exit" >/dev/null 2>&1 || {
        echo "⚠️  Posible conflicto de huella, limpiando..."
        ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e -x

# === CONFIGURACIÓN ===
NOMBRE="${1:-James Von Moltke}"
EMAIL="${2:-j.moltke@db.com}"
COMENTARIO="${3:-PGP}"
CLAVE_SALIDA="${4:-jmoltke}"
GPG_DIR="/home/markmur88/.gnupg"
KEYFILE="keygen_${CLAVE_SALIDA}.conf"

# === LOGGING ===
SCRIPT_NAME="$(basename "$0")"

LOG_FILE="$SCRIPTS_DIR/logs/00_18_04_generar_clave_pgp_njalla/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "👤 Usuario: $NOMBRE <$EMAIL>"

# === DEPENDENCIAS ===
if ! command -v gpg > /dev/null; then
    echo "❌ GnuPG no instalado. Ejecutá: sudo apt install gnupg"
    exit 1
fi

# === GENERAR CONFIG ===
cat > "$KEYFILE" <<EOF
%no-protection
Key-Type: default
Key-Length: 4096
Subkey-Type: default
Subkey-Length: 4096
Name-Real: $NOMBRE
Name-Comment: $COMENTARIO
Name-Email: $EMAIL
Expire-Date: 0
%commit
EOF

echo "🔐 Generando clave PGP automática (sin passphrase)..."
gpg --batch --generate-key "$KEYFILE"
rm "$KEYFILE"

# === EXPORTAR CLAVES ===
gpg --armor --output "${CLAVE_SALIDA}_public.asc" --export "$EMAIL"
gpg --armor --output "${CLAVE_SALIDA}_private.asc" --export-secret-keys "$EMAIL"
chmod 600 "${CLAVE_SALIDA}_private.asc"

echo "✅ Claves exportadas:"
echo "   🔑 Pública : ${CLAVE_SALIDA}_public.asc"
echo "   🔒 Privada : ${CLAVE_SALIDA}_private.asc"

# === VERIFICACIÓN ===
echo -e "\n📋 Claves actuales para $EMAIL:"
gpg --list-keys "$EMAIL"
