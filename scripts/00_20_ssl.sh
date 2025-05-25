#!/usr/bin/env bash
set -euo pipefail

echo -e "\033[1;35m🔐 Generando certificado SSL de desarrollo...\033[0m"
bash "/home/markmur88/Documentos/GitHub/api_bank_h2/scripts/00_generar_certificado_local.sh" || {
    echo -e "\033[1;31m❌ Error generando certificado SSL local.\033[0m"
    exit 1
}