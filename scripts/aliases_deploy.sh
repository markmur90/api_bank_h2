unalias d_ssl 2>/dev/null
#!/usr/bin/env bash

# === CLAVES SSH ===
ssh-add ~/.ssh/id_ed25519 && ssh-add ~/.ssh/vps_njalla_ed25519

# === ACCESOS DIRECTOS AL PROYECTO ===
alias api='cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias BKapi='cd "$HOME/Documentos/GitHub/api_bank_h2_BK" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias api_heroku='cd "$HOME/Documentos/GitHub/api_bank_heroku" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y'
alias monero='bash /opt/monero-gui/monero/monero-wallet-gui'


alias d_help='bash ./01_full.sh --help'
alias d_step='bash ./01_full.sh -s'
alias d_all='bash ./01_full.sh -a'
alias d_debug='bash ./01_full.sh -d'
alias d_menu='bash ./01_full.sh --menu'
alias d_status='bash ./scripts/diagnostico_entorno.sh'

# 🌐 Local (versión completa y versión corta)
unalias d_local_long 2>/dev/null
d_local_long() {
    bash ./01_full.sh --env=local --do-sys --do-zip --do-ports --do-docker --do-mac --do-ufw --do-clean --do-json-local --do-sync-local --do-sync-remote-db --do-run_local --do-user --do-run-web --do-pem --do-heroku --do-varher --do-verif-transf --do-deploy-vps --do-local-ssl "$@"
eval "$SHELL" -ic 'd_ssl'
}

unalias d_local_short 2>/dev/null
d_local_short() {
    bash ./01_full.sh --env=local -l -Q -I -r "$@"
# eval "$SHELL" -ic 'd_ssl'
}

unalias d_local 2>/dev/null
d_local() {
    bash ./01_full.sh --env=local -l -C -Z -S -M -x -Q -I -r "$@"
# eval "$SHELL" -ic 'd_ssl'
}

# 🔒 Local con modo dry-run (solo pruebas)
unalias d_local_dry_long 2>/dev/null
d_local_dry_long() {
    bash ./01_full.sh --env=local --dry-run --do-sys --do-zip --do-clean --do-json-local --do-sync-local --do-user --do-run-web "$@"
}

unalias d_local_dry 2>/dev/null
d_local_dry() {
    bash ./01_full.sh --env=local --dry-run -P -C -Q -I -U -V "$@"
}

# 🛰 Heroku completo
unalias d_heroku_long 2>/dev/null
d_heroku_long() {
    bash ./01_full.sh --env=heroku --do-sys --do-zip --do-clean --do-heroku --do-user --do-run-web --do-pem --do-ufw "$@"
}

unalias d_heroku 2>/dev/null
d_heroku() {
    bash ./01_full.sh --env=production -l -C -Z -B -H -S -Y -P -D -M -x -Q -I -V -u "$@"
}

# 🛡 Producción Njalla con todo
unalias d_njalla_long 2>/dev/null
d_njalla_long() {
    bash ./01_full.sh --env=production --do-sys --do-zip --do-clean --do-varher --do-user --do-run-web --do-heroku --do-verif-transf --do-deploy-vps "$@"
}
unalias d_njalla 2>/dev/null
d_njalla() {
    bash ./01_full.sh --env=production -P -C -H -U -V -u -B -v "$@"
}

# 🔒 Producción (solo variables importantes)
unalias d_production_vars_long 2>/dev/null
d_production_vars_long() {
    bash ./01_full.sh --env=production --do-sys --do-zip --do-clean --do-varher --do-user --do-run-web "$@"
}
unalias d_production_vars 2>/dev/null
d_production_vars() {
    bash ./01_full.sh --env=production -P -C -H -U -V "$@"
}

# 🧪 Producción mínima (despliegue y ejecución web solamente)
unalias d_prod_min_long 2>/dev/null
d_prod_min_long() {
    bash ./01_full.sh --env=production --do-deploy-vps --do-run-web "$@"
}
unalias d_prod_min 2>/dev/null
d_prod_min() {
    bash ./01_full.sh --env=production -v -V "$@"
}

# 🌐 Local con HTTPS (certificado dev)
alias d_local_ssl='bash ./scripts/run_local_ssl_env.sh'

# 🔑 SSL para pruebas (con certificado autofirmado)
alias d_ssl='python manage.py runsslserver --certificate certs/desarrollo.crt --key certs/desarrollo.key'



# # ╔═══════════════════════════════════════════════════════════╗
# # ║       Alias Profesionales — api_bank_h2 Deployment       ║
# # ╚═══════════════════════════════════════════════════════════╝

# alias d_help="bash 01_full.sh --help"
# alias d_step="bash 01_full.sh -s"
# alias d_all="bash 01_full.sh -a"
# alias d_debug="bash 01_full.sh -d"
# alias d_menu="bash 01_full.sh --menu"
# alias d_status="bash 01_full.sh --status"

# # 🌐 ENTORNO LOCAL
# alias d_local="bash 01_full.sh -P -D -M -x -C -Z -Q -I -L -S -V -p -u -H -B -v -E"
# alias d_local_long="bash 01_full.sh --do-ports --do-docker --do-mac --do-ufw --do-clean --do-zip --do-pgsql --do-migra --do-local --do-sync --do-verif-trans --do-pem --do-create-user --do-heroku --do-bdd --do-vps --do-cert"
# alias d_local_dry="bash 01_full.sh --dry-run -P -C -Q -I -U -V"
# alias d_local_dry_debug="bash 01_full.sh --dry-run -d"
# alias d_local_dry_long="bash 01_full.sh --dry-run --do-ports --do-clean --do-pgsql --do-migra --do-create-user --do-verif-trans"
# alias d_local_ssl="bash 01_full.sh -r"
# alias d_ssl="python manage.py runsslserver 0.0.0.0:8443"

# # ☁️ HEROKU
# alias d_heroku="bash 01_full.sh -P -C -u -U -V -p -x"
# alias d_heroku_long="bash 01_full.sh --do-ports --do-clean --do-create-user --do-varher --do-verif-trans --do-pem --do-ufw"
# alias d_heroku_cert="bash 01_full.sh --do-cert"

# # 🛡️ PRODUCCIÓN / VPS (Njalla)
# alias d_njalla="bash 01_full.sh -P -C -H -U -V -u -B -v"
# alias d_njalla_full="bash 01_full.sh -a"
# alias d_njalla_long="bash 01_full.sh --do-ports --do-clean --do-heroku --do-create-user --do-verif-trans --do-bdd --do-deploy-vps"
# alias d_production_vars="bash 01_full.sh -P -C -H -U -V"
# alias d_production_vars_long="bash 01_full.sh --do-ports --do-clean --do-heroku --do-create-user --do-verif-trans"
# alias d_prod_min="bash 01_full.sh -v -V"
# alias d_prod_min_long="bash 01_full.sh --do-deploy-vps --do-run-web"
