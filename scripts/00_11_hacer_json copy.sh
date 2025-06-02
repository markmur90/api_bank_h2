#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backup/sql"
LOG_FILE="$SCRIPT_DIR/logs/respaldo_local_cifrado.log"

DB_NAME="mydatabase"
DB_USER="markmur88"
KEY_EMAIL="jmoltke@protonmail.com"
GPG_PUBLIC_KEY="$PROJECT_DIR/gpg_keys/jmoltke_public.asc"

# 💾 Archivos
PLAIN="$BACKUP_DIR/backup_local.sql"
CIFRADO="$PLAIN.gpg"

mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# 🎯 Validación GPG
if ! gpg --list-keys "$KEY_EMAIL" &>/dev/null; then
  echo "ℹ️ Importando clave pública $KEY_EMAIL..."
  gpg --import "$GPG_PUBLIC_KEY"
fi

{
echo "📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "📦 Backup local → $CIFRADO"
echo "════════════════════════════════════════"
echo -e "\033[1;32m🚀 Dump de PostgreSQL...\033[0m"
pg_dump --no-owner --no-acl -U "$DB_USER" "$DB_NAME" > "$PLAIN"

echo "🔐 Cifrando con GPG..."
gpg --yes --batch --output "$CIFRADO" --encrypt --recipient "$KEY_EMAIL" "$PLAIN"

echo -e "\033[1;32m✅ Backup cifrado en: $CIFRADO\033[0m"
} | tee -a "$LOG_FILE"
