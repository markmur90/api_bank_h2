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
ad_local() {cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && d_local && code . "$@"}

unalias d_env 2>/dev/null
d_env() {cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear "$@"}

unalias d_mig 2>/dev/null
d_mig() {d_env && python3 manage.py makemigrations && python3 manage.py migrate && python3 manage.py collectstatic --noinput && python3 manage.py runserver 8002 "$@"}

unalias d_local 2>/dev/null
d_local() {d_env && bash ./01_full.sh --env=local -Z -C -S -Q -I -l -r "$@"}

unalias d_heroku 2>/dev/null
d_heroku() {d_env && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B -r "$@"}

unalias d_njalla 2>/dev/null
d_njalla() {d_env && bash ./01_full.sh --env=local -Z -C -S -Q -I -l -H -B -v -r "$@"}

unalias d_pgm 2>/dev/null
d_pgm() {d_env && bash ./01_full.sh --env=local -Z -C -Q -I -l -S -E -p "$@"}

unalias d_hek 2>/dev/null
d_hek() {d_env && bash ./01_full.sh --env=local -B -H -u "$@"}

unalias d_back 2>/dev/null
d_back() {d_env && bash ./01_full.sh --env=local -C -Z "$@"}

unalias d_sys 2>/dev/null
d_sys() {d_env && bash ./01_full.sh --env=local -Y -P -D -M -x "$@"}

unalias d_cep 2>/dev/null
d_cep() {d_env && bash ./01_full.sh --env=local -p -E "$@"}

unalias d_vps 2>/dev/null
d_vps() {d_env && bash ./01_full.sh --env=local -v "$@"}



