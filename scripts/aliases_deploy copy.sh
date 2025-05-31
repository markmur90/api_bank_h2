#!/usr/bin/env bash

# === CLAVES SSH ===

# === ACCESOS DIRECTOS AL PROYECTO ===

alias api='cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && d_sys'
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
export VPS_API_DIR="/home/markmur88/coretransapi"
ssh-add ~/.ssh/id_ed25519 && ssh-add ~/.ssh/vps_njalla_nueva

# === ALIAS VPS ===


alias vps_login="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP"
alias vps_logs="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'journalctl -u gunicorn.service -f'"
alias vps_nginx="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'tail -f /var/log/nginx/error.log'"
alias vps_reload="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'systemctl restart gunicorn && systemctl reload nginx'"
alias vps_status="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'systemctl status gunicorn'"
alias vps_check="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'netstat -tulnp | grep LISTEN'"
alias vps_sync="api && rsync -avz -e \"ssh -i $SSH_KEY -p $VPS_PORT\" ./ $VPS_USER@$VPS_IP:$VPS_API_DIR/"
alias vps_cert="api && ssh -i $SSH_KEY -p $VPS_PORT $VPS_USER@$VPS_IP 'sudo certbot renew --dry-run'"

# 🧪 Test conexión con timeout de 3s
alias vps_ping="api && timeout 3 bash -c '</dev/tcp/$VPS_IP/$VPS_PORT' && echo '✅ VPS accesible' || echo '❌ Sin respuesta del VPS'"


# 🌐 Local (versión completa y versión corta)
unalias d_njalla 2>/dev/null
d_njalla() {ad_local && d_env && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B -v && ad_heroku && code . "$@"}

unalias d_env 2>/dev/null
d_env() {source "$HOME/Documentos/Entorno/envAPP/bin/activate" "$@"}

unalias d_mig 2>/dev/null
d_mig() {python3 manage.py makemigrations && python3 manage.py migrate && python3 manage.py collectstatic --noinput && clear "$@"}

unalias d_local 2>/dev/null
d_local() {api && bash ./01_full.sh --env=local -Z -C -S -Q -I -l && code . "$@"}

unalias d_heroku 2>/dev/null
d_heroku() {api && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B && ad_heroku "$@"}

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
d_vps() {api && bash ./01_full.sh -v "$@"}



# === MENÚ INTERACTIVO ===
deploy_menu() {
    local options=(
        "api ➤ - ➤ Entorno y api_bank_h2"
        "BKapi ➤ - ➤ Entorno y api_bank_h2_BK"
        "api_heroku ➤ - ➤ Entorno y api_bank_h2_heroku"
        "update ➤ - ➤ Actualizar sistema"
        "d_all ➤ -a ➤ Todo automático (producción completa)"
        "d_step ➤ -s ➤ Modo paso a paso"
        "d_debug ➤ -d ➤ Diagnóstico"
        "d_status ➤ -d ➤ Diagnóstico Entorno Local"
        "d_local ➤ - ➤ local setup completo"
        "d_heroku ➤ - ➤ deploy completo a Heroku"
        "d_njalla ➤ - ➤ deploy completo a Njalla"
        "d_env ➤ - ➤ Activar entorno"
        "d_mig ➤ - ➤ Migraciones directorio local"
        "d_pgm ➤ - ➤ PostgreSQL, Migraciones y Carga BDD"
        "d_hek ➤ - ➤ Syncronizar Heroku y BDD"
        "d_bak ➤ - ➤ Zip y Clean"
        "d_sys ➤ - ➤ Actualiza, Puertos, Docker, MAC, UFW"
        "d_cep ➤ - ➤ PEM y Certbot"
        "d_vps ➤ - ➤ VPS"
        "vps_login ➤ - ➤ Ingreso al VPS"
        "vps_logs ➤ - ➤ Logs del VPS"
        "vps_nginx ➤ - ➤ Tareas del VPS"
        "vps_reload ➤ - ➤ Reinicio de gunicorn y nginx del VPS"
        "vps_status ➤ - ➤ Status gunicorn del VPS"
        "vps_check ➤ - ➤ Netstat del VPS"
        "vps_sync ➤ - ➤ Sincronización del directorio actual al VPS"
        "vps_cert ➤ - ➤ Regenerar certificados certbot del VPS"
        "vps_ping ➤ - ➤ Respuesta del VPS"
    )

    local choice
    choice=$(printf "%s
" "${options[@]}" | fzf --prompt='▶ Selecciona despliegue:' --height=40% --border --reverse --no-info)
    local cmd
    cmd=$(echo "$choice" | awk '{print $1}')
    if [[ -n "$cmd" ]]; then
        echo -e "\n🔹 Ejecutando: \033[1;36m$cmd\033[0m"
        actual_cmd=$(alias "$cmd" 2>/dev/null | awk -F"'" '{print $2}')
        echo -e "\033[1;33m➡️ Comando real:\033[0m $actual_cmd"
        echo -e "\n\033[1;32m[LOG] Salida de ejecución:\033[0m\n"
        eval "$actual_cmd"
    else
        echo "❌ Cancelado."
    fi
}
