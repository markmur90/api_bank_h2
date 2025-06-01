#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backup/sql"
LOG_FILE="$SCRIPT_DIR/logs/restaurar_local_descifrado.log"

DB_NAME="mydatabase"
DB_USER="markmur88"
KEY_EMAIL="jmoltke@protonmail.com"
GPG_PRIVATE_KEY="$PROJECT_DIR/gpg_keys/jmoltke_private.asc"

CIFRADO="$BACKUP_DIR/backup_local.sql.gpg"
PLANO="$BACKUP_DIR/backup_descifrado.sql"

mkdir -p "$(dirname "$LOG_FILE")"

# 🎯 Validación GPG
if ! gpg --list-secret-keys "$KEY_EMAIL" &>/dev/null; then
  echo "ℹ️ Importando clave privada $KEY_EMAIL..."
  gpg --import "$GPG_PRIVATE_KEY"
fi

{
echo "📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "📂 Restaurando desde → $CIFRADO"
echo "════════════════════════════════════════"
echo -e "\033[1;36m🔓 Descifrando backup...\033[0m"
gpg --yes --batch --output "$PLANO" --decrypt "$CIFRADO"

echo "💾 Restaurando con psql..."
psql -U "$DB_USER" -d "$DB_NAME" < "$PLANO"

echo -e "\033[1;36m✅ Restauración completada.\033[0m"
} | tee -a "$LOG_FILE"
