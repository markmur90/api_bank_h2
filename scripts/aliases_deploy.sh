#!/usr/bin/env bash

# === CLAVES SSH ===
ssh-add ~/.ssh/id_ed25519 && ssh-add ~/.ssh/vps_njalla_ed25519

# === ACCESOS DIRECTOS AL PROYECTO ===
alias api='cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias BKapi='cd "$HOME/Documentos/GitHub/api_bank_h2_BK" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias api_heroku='cd "$HOME/Documentos/GitHub/api_bank_heroku" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y'
alias monero='bash /opt/monero-gui/monero/monero-wallet-gui'

# === DESPLIEGUE PROFESIONAL ===

# 🧭 Ayuda y menú
alias d_help='bash ./01_full.sh --help'
alias d_step='bash ./01_full.sh -s'
alias d_all='bash ./01_full.sh -a'
alias d_debug='bash ./01_full.sh -d'
alias d_menu='bash ./01_full.sh --menu'
alias d_status='bash ./scripts/diagnostico_entorno.sh'

# 🌐 Local (versión completa y versión corta)
alias d_local_long='bash ./01_full.sh --env=local -a --do-sys --do-zip --do-ports --do-docker --do-mac --do-ufw --do-clean --do-json-local --do-sync-local --do-sync-remote-db --do-run_local --do-user --do-run-web --do-pem --do-heroku --do-varher --do-verif-transf --do-deploy-vps --do-local-ssl && d_ssl'
alias d_local='bash ./01_full.sh --env=local -a -Y -P -D -M -x -C -Z -Q -I -L -S -U -V -p -u -H -B -v -E && d_ssl'

# 🔒 Local con modo dry-run (solo pruebas)
alias d_local_dry_long='bash ./01_full.sh --env=local -a --dry-run --do-sys --do-zip --do-clean --do-json-local --do-sync-local --do-user --do-run-web'
alias d_local_dry='bash ./01_full.sh --env=local -a --dry-run -Y -P -C -Q -I -U -V'

# 🛰 Heroku completo
alias d_heroku_long='bash ./01_full.sh --env=heroku -a --do-sys --do-zip --do-clean --do-heroku --do-user --do-run-web --do-pem --do-ufw'
alias d_heroku='bash ./01_full.sh --env=heroku -a -Y -P -C -u -U -V -p -x'

# 🛡 Producción Njalla con todo
alias d_njalla_long='bash ./01_full.sh --env=production -a --do-sys --do-zip --do-clean --do-varher --do-user --do-run-web --do-heroku --do-verif-transf --do-deploy-vps'
alias d_njalla='bash ./01_full.sh --env=production -a -Y -P -C -H -U -V -u -B -v'

# 🔒 Producción (solo variables importantes)
alias d_production_vars_long='bash ./01_full.sh --env=production -a --do-sys --do-zip --do-clean --do-varher --do-user --do-run-web'
alias d_production_vars='bash ./01_full.sh --env=production -a -Y -P -C -H -U -V'

# 🧪 Producción mínima (despliegue y ejecución web solamente)
alias d_prod_min_long='bash ./01_full.sh --env=production -a --do-deploy-vps --do-run-web'
alias d_prod_min='bash ./01_full.sh --env=production -a -v -V'

# 🌐 Local con HTTPS (certificado dev)
alias d_local_ssl='bash ./scripts/run_local_ssl_env.sh'

# 🔑 SSL para pruebas (con certificado autofirmado)
alias d_ssl='python manage.py runsslserver --certificate certs/desarrollo.crt --key certs/desarrollo.key'
