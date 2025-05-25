#!/usr/bin/env bash
set -euo pipefail

echo -e "\033[7;30m🚀 Generando PEM...\033[0m"
python3 manage.py genkey
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""