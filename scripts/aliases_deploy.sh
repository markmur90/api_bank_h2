#!/usr/bin/env bash

# === ACCESOS DIRECTOS AL PROYECTO ===

alias api='cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear'
alias BKapi='cd "$HOME/Documentos/GitHub/api_bank_h2_BK" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias api_heroku='cd "$HOME/Documentos/GitHub/api_bank_heroku" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear'
alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y'
alias monero='bash /opt/monero-gui/monero/monero-wallet-gui'


alias d_help='api && bash ./01_full.sh --help'
alias d_step='api && bash ./01_full.sh -s'
alias d_all='api && bash ./01_full.sh -a'
alias d_debug='api && bash ./01_full.sh -d'
alias d_menu='api && bash ./01_full.sh --menu'
alias d_status='api && bash ./scripts/diagnostico_entorno.sh'

# === VARIABLES VPS (personalizables) ===
export VPS_USER="root"
export VPS_IP="80.78.30.242"
export VPS_PORT="49222"
export SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
export VPS_API_DIR="/home/markmur88/api_bank_heroku"
ssh-add ~/.ssh/id_ed25519 && ssh-add ~/.ssh/vps_njalla_nueva

RUTA_LOCAL="$HOME/Documentos/GitHub/api_bank_h2/"
RUTA_REMOTA="/home/markmur88/api_bank_heroku/"

# === ALIAS VPS ===
alias vps_login="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP"
alias vps_check="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'netstat -tulnp | grep LISTEN'"
alias vps_ping="api && timeout 3 bash -c '</dev/tcp/$VPS_IP/$VPS_PORT' && echo '✅ VPS accesible' || echo '❌ Sin respuesta del VPS'"


alias vps_logs="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'journalctl -u gunicorn.service -f'"
alias vps_nginx="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'tail -f /var/log/nginx/error.log'"
alias vps_reload="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'systemctl restart gunicorn && systemctl reload nginx'"
alias vps_status="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'systemctl status gunicorn'"
alias vps_cert="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'sudo certbot renew --dry-run'"
alias vps_sync="api && rsync -avz -e "ssh -i $SSH_KEY -p $VPS_PORT" "$RUTA_LOCAL" "${VPS_USER}@${VPS_IP}:${RUTA_REMOTA}" "
alias pg_njalla_local='ssh -i ~/.ssh/vps_njalla_nueva -p 49222 -L 5433:127.0.0.1:5432 root@80.78.30.242'
# psql -h 127.0.0.1 -p 5433 -U <usuario_db> -d <nombre_db>

# 🧪 Test conexión con timeout de 3s


# 🌐 Local (versión completa y versión corta)

unalias d_njalla 2>/dev/null
d_njalla() {d_env && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B -v "$@"}

unalias d_env 2>/dev/null
d_env() {source "$HOME/Documentos/Entorno/envAPP/bin/activate" "$@"}

unalias d_mig 2>/dev/null
d_mig() {python3 manage.py makemigrations && python3 manage.py migrate && python3 manage.py collectstatic --noinput && clear "$@"}

unalias d_local 2>/dev/null
d_local() {api && bash ./01_full.sh --env=local -Z -C -S -Q -I -l "$@"}

unalias d_heroku 2>/dev/null
d_heroku() {api && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B "$@"}

unalias d_pgm 2>/dev/null
d_pgm() {api && bash ./01_full.sh -Q -I -l "$@"}

unalias d_hek 2>/dev/null
d_hek() {api && bash ./01_full.sh -B -H "$@"}

unalias d_back 2>/dev/null
d_back() {api && bash ./01_full.sh -C -Z "$@"}

unalias d_sys 2>/dev/null
d_sys() {api && bash ./01_full.sh -Y -P -D -M -x "$@"}

unalias d_cep 2>/dev/null
d_cep() {api && bash ./01_full.sh -p -E "$@"}

unalias d_vps 2>/dev/null
d_vps() {d_env && bash ./01_full.sh -v "$@"}

