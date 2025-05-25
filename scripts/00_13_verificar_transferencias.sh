#!/usr/bin/env bash
set -euo pipefail

echo -e "\033[7;30m🚀 Verificando logs transferencias...\033[0m"
python manage.py verificar_transferencias --fix -c -j
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""