#!/usr/bin/env bash
set -euo pipefail

echo -e "\033[1;36m🌐 Levantando entorno local en https://localhost:8443...\033[0m"
bash ./scripts/run_local_ssl_env.sh || {
    echo -e "\033[1;31m❌ Error al ejecutar entorno local SSL.\033[0m"
    exit 1
}
echo -e "\033[1;32m✅ Entorno local SSL finalizado.\033[0m"
echo ""