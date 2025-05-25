#!/usr/bin/env bash
set -euo pipefail

echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m"
python3 manage.py loaddata bdd_local.json
echo -e "\033[7;30m✅ ¡Subido JSON Local!\033[0m"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""