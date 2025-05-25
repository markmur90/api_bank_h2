#!/usr/bin/env bash
set -euo pipefail

echo -e "\033[7;30m🚀 Creando usuario...\033[0m"
python3 manage.py createsuperuser
echo -e "\033[7;30m✅ ¡Usuario creado!\033[0m"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""