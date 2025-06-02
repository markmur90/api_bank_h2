#!/usr/bin/env bash
set -euo pipefail

echo "📡 Sincronizando VPS con GitHub..."
cd ~/api_bank_heroku

# Verificar y stashear si hay cambios locales
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "🧠 Cambios locales detectados. Haciendo stash automático..."
    git stash push -u -m "Stash automático antes de pull remoto"
fi

# Pull usando clave correcta
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519" git pull origin api-bank

echo "🔁 Reiniciando servicios..."
sudo systemctl restart gunicorn
sudo systemctl reload nginx

echo "✅ Servicios reiniciados. Estado:"
systemctl status gunicorn | head -n 10
