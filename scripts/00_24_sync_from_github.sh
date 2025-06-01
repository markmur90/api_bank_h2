#!/usr/bin/env bash
set -euo pipefail

echo "📡 Sincronizando VPS con GitHub..."
cd ~/api_bank_heroku
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519" git push origin api-bank

echo "🔁 Reiniciando servicios..."
sudo systemctl restart gunicorn
sudo systemctl reload nginx

echo "✅ Servicios reiniciados. Estado:"
systemctl status gunicorn | head -n 10
