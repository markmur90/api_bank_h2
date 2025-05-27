#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"
mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"
Abortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname "$LOG_DEPLOY")"

echo -e "\033[7;30m🚀 Creando usuario...\033[0m" | tee -a "$LOG_DEPLOY"

python3 manage.py shell <<EOF | tee -a "$LOG_DEPLOY"
from django.contrib.auth import get_user_model
User = get_user_model()
username = "493069k1"
email = "j.moltke@db.com"
password = "bar1588623"
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, email=email, password=password)
    print(f"✅ Superusuario '{username}' creado exitosamente.")
else:
    print(f"ℹ️ El superusuario '{username}' ya existe.")
EOF

echo -e "\033[7;30m✅ ¡Usuario creado!\033[0m" | tee -a "$LOG_DEPLOY"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a "$LOG_DEPLOY"
echo "" | tee -a "$LOG_DEPLOY"
