#!/usr/bin/env bash
set -e

URL="https://api.coretransapi.com"

echo "🌐 Verificando headers HTTPS en: $URL"
echo "==========================================="
curl -s -D - "$URL" -o /dev/null | grep -Ei 'strict-transport-security|x-frame-options|x-content-type-options|referrer-policy|x-xss-protection|content-security-policy|location'
echo "==========================================="
echo "✅ Revisión completada."
