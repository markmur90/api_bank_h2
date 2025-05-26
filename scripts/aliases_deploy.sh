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
unalias ad_local 2>/dev/null
ad_local() {
    cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && d_local && code . "$@"
}
unalias ad_short_local 2>/dev/null
ad_short_local() {
    cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && d_local_short && code . "$@"
}
unalias d_local_short 2>/dev/null
d_local_short() {
    bash ./01_full.sh --env=local -l -Q -I "$@"
# eval "$SHELL" -ic 'd_ssl'
}
unalias d_local 2>/dev/null
d_local() {
    bash ./01_full.sh --env=local -l -C -Z -S -M -x -Q -I -r "$@"
}
unalias d_local_dry 2>/dev/null
d_local_dry() {
    bash ./01_full.sh --env=local --dry-run -P -C -Q -I -U -V "$@"
}
unalias d_heroku 2>/dev/null
d_heroku() {
    bash ./01_full.sh --env=production -C -Z -H -u -S -x -Q -I -r "$@"
}
unalias d_njalla 2>/dev/null
d_njalla() {
    bash ./01_full.sh --env=production -P -C -H -U -V -u -B -v "$@"
}
unalias d_production_vars 2>/dev/null
d_production_vars() {
    bash ./01_full.sh --env=production -P -C -H -U -V "$@"
}
unalias d_prod_min 2>/dev/null
d_prod_min() {
    bash ./01_full.sh --env=production -v -V "$@"
}



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
