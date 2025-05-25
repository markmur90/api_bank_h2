#!/usr/bin/env bash
set -euo pipefail

HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
SECRET_KEY="L3hesOa21ZGRsk0TsVvKMI6kWuv8d-ZAGIfP87i4Hv0"

echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""
# Configurar variable DJANGO_SETTINGS_MODULE
echo -e "\033[7;36m🔧 Configurando DJANGO_SETTINGS_MODULE en Heroku...\033[0m"
heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production
# CLAVE_SEGURA=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(64)))")
heroku config:set DJANGO_SECRET_KEY=$SECRET_KEY
heroku config:set DJANGO_DEBUG=True
heroku config:set DJANGO_ALLOWED_HOSTS=api.coretransapi.com,apibank2-d42d7ed0d036.herokuapp.com,127.0.0.1,0.0.0.0
# heroku config:set DB_CLIENT_ID=tu-client-id-herokuPtf8454Jd55
# heroku config:set DB_CLIENT_SECRET=tu-client-secret-heroku
heroku config:set DB_TOKEN_URL=https://simulator-api.db.com:443/gw/dbapi/token
heroku config:set DB_AUTH_URL=https://simulator-api.db.com:443/gw/dbapi/authorize
heroku config:set DB_API_URL=https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer
heroku config:set DB_SCOPE=sepa_credit_transfers
heroku config:set API_ORIGIN=https://api.db.com
heroku config:set TIMEOUT_REQUEST=3600
heroku config:set DISABLE_COLLECTSTATIC=1
set -a; source .env; set +a
heroku config:set PRIVATE_KEY_B64=$(base64 -w 0 schemas/keys/ecdsa_private_key.pem)
heroku config:get PRIVATE_KEY_B64 | base64 -d | head
heroku config:set OAUTH2_REDIRECT_URI=https://apibank2-d42d7ed0d036.herokuapp.com/oauth2/callback/