#!/usr/bin/env bash

# === ACCESOS DIRECTOS AL PROYECTO ===

alias api='cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" '
alias BKapi='cd "$HOME/Documentos/GitHub/api_bank_h2_BK" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias api_heroku='cd "$HOME/Documentos/GitHub/api_bank_heroku" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" '
alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y'
alias monero='bash /opt/monero-gui/monero/monero-wallet-gui'


alias start_notif_i='bash ~/Documentos/GitHub/api_bank_h2/scripts/start_notificadores_interactivo.sh'
alias notificadores='bash ~/Documentos/GitHub/api_bank_h2/scripts/gestionar_notificadores.sh'


alias d_help='api && bash ./01_full.sh --help'
alias d_step='api && bash ./01_full.sh -s'
alias d_all='api && bash ./01_full.sh -a'
alias d_debug='api && bash ./01_full.sh -d'
alias d_menu='api && bash ./01_full.sh --menu'
alias d_status='api && bash ./scripts/diagnostico_entorno.sh'

alias d_Gsync='api && ./01_full.sh -S -Gi'


# === VARIABLES ENTORNOS ===
unalias d_local 2>/dev/null
d_local() {api && bash ./01_full.sh --env=local -Z -C -S -Q -I -l "$@"}
unalias d_heroku 2>/dev/null
d_heroku() {api && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B "$@"}
unalias d_njalla 2>/dev/null
d_njalla() {api && bash ./01_full.sh --env=production -Y -P -D -M -x -Z -C -S -Q -I -l -Gi "$@"}


# === VARIABLES LOCALES ===
unalias d_env 2>/dev/null
d_env() {source "$HOME/Documentos/Entorno/envAPP/bin/activate" "$@"}
unalias d_mig 2>/dev/null
d_mig() {python3 manage.py makemigrations && python3 manage.py migrate && python3 manage.py collectstatic --noinput && clear "$@"}


# === VARIABLES API ===
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


# === VARIABLES VPS (personalizables) ===
export VPS_USER="markmur88"
export VPS_IP="80.78.30.242"
export VPS_PORT="22"
export SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
export VPS_SSH_KEY="/home/markmur88/.ssh/id_ed25519"
export VPS_API_DIR="/home/markmur88/api_bank_heroku"

ssh-add ~/.ssh/id_ed25519 && ssh-add ~/.ssh/vps_njalla_nueva

# === FUNCIÓN AUXILIAR ===
vps_exec() {
    api && ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "$@"
}

# === ALIAS VPS ===
alias vps_tor='vps_exec "sudo cat /var/lib/tor/hidden_service/hostname"'
alias vps_logs='vps_exec "sudo journalctl -u gunicorn.service -f"'
alias vps_nginx='vps_exec "tail -f /var/log/nginx/error.log"'
alias vps_reload='vps_exec "systemctl restart gunicorn && systemctl reload nginx"'
alias vps_status='vps_exec "systemctl status gunicorn"'
alias vps_cert='vps_exec "sudo certbot renew --dry-run"'
alias vps_check='vps_exec "netstat -tulnp | grep LISTEN"'
alias vps_ping='api && timeout 3 bash -c "</dev/tcp/$VPS_IP/$VPS_PORT" && echo "✅ VPS accesible" || echo "❌ Sin respuesta del VPS"'

alias vps_sync_all='bash ~/Documentos/GitHub/api_bank_h2/scripts/sync_local_and_vps.sh'




# === Login directo ===
alias vps_l_root='api && ssh -i "$SSH_KEY" -p "$VPS_PORT" root@"$VPS_IP"'
alias vps_l_user='api && ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP"'

# === PostgreSQL Local desde VPS ===
alias pg_njalla_local='ssh -i ~/.ssh/vps_njalla_nueva -p 49222 -L 5433:127.0.0.1:5432 root@80.78.30.242'
# psql -h 127.0.0.1 -p 5433 -U <usuario_db> -d <nombre_db>

# === Sincronización segura ===
alias vps_sync='api && bash $HOME/Documentos/GitHub/api_bank_h2/scripts/vps_sync.sh'

alias vps_sync_lastlog='
LOG_DIR=$(git rev-parse --show-toplevel 2>/dev/null || find "$PWD" -type f -name "manage.py" -exec dirname {} \; | head -n1)/scripts/logs/sync
[ -d "$LOG_DIR" ] && less "$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | head -n1)" || echo "❌ No hay logs de sincronización."
'


