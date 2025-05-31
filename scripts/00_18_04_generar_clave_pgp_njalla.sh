#!/usr/bin/env bash

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
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e

# === CONFIGURACIÓN ===
NOMBRE="${1:-James Von Moltke}"
EMAIL="${2:-j.moltke@db.com}"
COMENTARIO="${3:-PGP}"
CLAVE_SALIDA="${4:-jmoltke}"
GPG_DIR="$HOME/.gnupg"
KEYFILE="keygen_${CLAVE_SALIDA}.conf"

# === LOGGING ===
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/00_18_04_generar_clave_pgp_njalla/${SCRIPT_NAME%.sh}.log"
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
