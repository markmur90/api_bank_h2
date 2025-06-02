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
    clear && api && ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "$@"
}

# === TOR ===
alias vps_tor='vps_exec "sudo cat /var/lib/tor/hidden_service/hostname"'
alias tor_diag='bash ~/Documentos/GitHub/api_bank_h2/scripts/check_torrc.sh'
alias tor_newip='bash ~/Documentos/GitHub/api_bank_h2/scripts/rotate_tor_ip.sh'
alias tor_refresh='tor_diag && tor_newip'
alias sync_configs='bash ~/Documentos/GitHub/api_bank_h2/scripts/sync_configs_from_vps.sh'
alias push_configs='bash ~/Documentos/GitHub/api_bank_h2/scripts/sync_configs_to_vps.sh'




# ─── 📦 Logs del sistema ────────────────────────────────
alias vps_supervisor='vps_exec "tail -f /var/log/supervisor/coretransapi.err.log"'

# ─── 🌐 Logs de NGINX ──────────────────────────────────
alias vps_nginx_err='vps_exec "tail -f /var/log/nginx/error.log"'
alias vps_nginx_access='vps_exec "tail -f /var/log/nginx/access.log"'
alias vps_nginx_all='vps_exec "tail -f /var/log/nginx/error.log /var/log/nginx/access.log"'

# 🪵 Todos los logs críticos juntos
alias vps_logs_all='vps_exec "tail -f /var/log/supervisor/coretransapi.err.log /var/log/nginx/error.log /var/log/nginx/access.log"'





# Recarga Gunicorn vía Supervisor + NGINX
alias vps_reload='vps_exec "sudo supervisorctl restart coretransapi && sudo systemctl reload nginx"'

# Ver estado general del servicio de app
alias vps_status='vps_exec "sudo supervisorctl status coretransapi"'

alias vps_cert='vps_exec "sudo certbot renew --dry-run"'
alias vps_check='vps_exec "netstat -tulnp | grep LISTEN"'

alias vps_ping='api && timeout 3 bash -c "</dev/tcp/$VPS_IP/$VPS_PORT" && echo "✅ VPS accesible" || echo "❌ Sin respuesta del VPS"'

# === Login directo ===
alias vps_l_root='api && ssh -i "$SSH_KEY" -p "$VPS_PORT" root@"$VPS_IP"'
alias vps_l_user='api && ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP"'

# === PostgreSQL Local desde VPS ===
alias pg_njalla_local='ssh -i ~/.ssh/vps_njalla_nueva -p 49222 -L 5433:127.0.0.1:5432 markmur88@80.78.30.242'
# psql -h 127.0.0.1 -p 5433 -U <usuario_db> -d <nombre_db>

# === Sincronización segura ===
alias vps_locsync='api && bash $HOME/Documentos/GitHub/api_bank_h2/scripts/vps_sync.sh'

# === Sincronización por GitHub ===

alias vps_gitsync='bash ~/Documentos/GitHub/api_bank_h2/scripts/00_14_sincronizacion_archivos.sh && bash ~/Documentos/GitHub/api_bank_h2/scripts/sync_local_and_vps.sh && api'

alias vps_logsync='
LOG_DIR=$(git rev-parse --show-toplevel 2>/dev/null || find "$PWD" -type f -name "manage.py" -exec dirname {} \; | head -n1)/scripts/logs/sync
[ -d "$LOG_DIR" ] && less "$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | head -n1)" || echo "❌ No hay logs de sincronización."
'


alias d_hp_aliases='clear && 
echo -e "\n\033[1;36m📌 ALIAS RÁPIDOS DISPONIBLES:\033[0m"
echo -e "  \033[1;33md_local\033[0m                 Despliegue local completo (env=local)"
echo -e "  \033[1;33md_heroku\033[0m                Despliegue completo a Heroku (env=production)"
echo -e "  \033[1;33md_njalla\033[0m                Despliegue completo a VPS Njalla (env=production + GitHub)"
# echo -e "  \033[1;33md_env\033[0m                   Activa entorno virtual local"
# echo -e "  \033[1;33md_mig\033[0m                   Aplica migraciones y colecta estáticos"

echo -e "  \033[1;33md_pgm\033[0m                   Carga PostgreSQL y migraciones"
echo -e "  \033[1;33md_back\033[0m                  Ejecuta backup clean + zip"
echo -e "  \033[1;33md_sys\033[0m                   Ejecuta ajustes de sistema VPS (UFW, puertos, etc.)"
# echo -e "  \033[1;33md_hek\033[0m                   Ejecuta deploy Heroku completo"
# echo -e "  \033[1;33md_cep\033[0m                   Genera claves PEM + certificados SSL"
# echo -e "  \033[1;33md_vps\033[0m                   Ejecuta post-deploy en VPS (coretransapi)"

echo -e "\n  \033[1;33mvps_l_user\033[0m              Acceso SSH al VPS como usuario markmur88"
echo -e "  \033[1;33mvps_l_root\033[0m              Acceso SSH al VPS como root"
echo -e "  \033[1;33mvps_reload\033[0m              Reinicia coretransapi (Supervisor) + recarga NGINX"
echo -e "  \033[1;33mvps_status\033[0m              Estado del servicio coretransapi supervisado"
# echo -e "  \033[1;33mvps_cert\033[0m                Simula renovación SSL vía certbot"
echo -e "  \033[1;33mvps_check\033[0m               Muestra puertos abiertos en VPS"
echo -e "  \033[1;33mvps_ping\033[0m                Verifica conexión con el VPS vía TCP"

echo -e "\n  \033[1;33mvps_supervisor\033[0m          Logs de errores del servicio supervisado (coretransapi)"
echo -e "  \033[1;33mvps_nginx_err\033[0m           Logs de errores de NGINX"
echo -e "  \033[1;33mvps_nginx_access\033[0m        Logs de accesos de NGINX"
echo -e "  \033[1;33mvps_nginx_all\033[0m           Logs combinados de error + acceso NGINX"
echo -e "  \033[1;33mvps_logs_all\033[0m            Logs combinados de Supervisor + NGINX (error + acceso)"

echo -e "\n  \033[1;33mvps_locsync\033[0m             Sincroniza proyecto local al VPS directamente"
echo -e "  \033[1;33mvps_gitsync\033[0m             Corre deploy a GitHub + pull remoto en VPS"
echo -e "  \033[1;33mvps_logsync\033[0m             Muestra último log de sincronización de archivos"
echo -e "  \033[1;33mpg_njalla_local\033[0m         Túnel SSH para acceder a PostgreSQL remoto localmente"
'

alias d_hp_scripts='clear && 
echo -e "\n\033[1;36m📁 SCRIPTS DISPONIBLES:\033[0m"
echo -e "  \033[1;33m01_full.sh\033[0m                 Script principal de despliegue y tareas compuestas"
echo -e "  \033[1;33m00_16_01_subir_GitHub.sh\033[0m   Subida de código a GitHub + Heroku"
echo -e "  \033[1;33m00_14_sincronizacion_archivos.sh\033[0m Sincroniza archivos estáticos/locales"
echo -e "  \033[1;33mvps_sync.sh\033[0m               Sincronización directa de código al VPS"
echo -e "  \033[1;33msync_local_and_vps.sh\033[0m      Subida a GitHub + sync remoto VPS"
echo -e "  \033[1;33m00_24_sync_from_github.sh\033[0m  Pull desde GitHub en el VPS y reinicio de servicios"
echo -e "  \033[1;33mdiagnostico_entorno.sh\033[0m     Diagnóstico del sistema y entorno virtual"
'
alias d_hp_notif='clear && 
echo -e "\n\033[1;36m🔔 HERRAMIENTAS DE NOTIFICACIÓN:\033[0m"
echo -e "  \033[1;33mstart_notif_i\033[0m              Inicia notificaciones pidiendo intervalo interactivo"
echo -e "  \033[1;33mnotificadores\033[0m              Script interactivo para iniciar/detener/reiniciar notificadores"
echo -e "  \033[1;33mnotify_service_time <min>\033[0m  Cambia intervalo de notificador con systemd (si estuviera activo)"
echo -e "  \033[1;33mnotify_clock_time <min>\033[0m    Notificador de reloj exacto (notificador_30.sh)"
# echo -e "  \033[1;33mpid_notify\033[0m                 Muestra el PID del proceso notificador"
# echo -e "  \033[1;33mproc_notify\033[0m                Lista procesos relacionados al notificador"
# echo -e "  \033[1;33mrestart_notificar\033[0m          Reinicia el notificador interactivamente"
'
alias d_hp_logs='clear && 
echo -e "\n\033[1;36m🪵 LOGS DISPONIBLES:\033[0m"

echo -e "\n\033[1;33m🔁 Sincronización:\033[0m"
echo -e "  ~/Documentos/GitHub/api_bank_h2/scripts/logs/sync/*.log"
echo -e "  Último log con: \033[1;33mvps_sync_lastlog\033[0m"

echo -e "\n\033[1;33m📦 Despliegue y push:\033[0m"
echo -e "  ~/Documentos/GitHub/api_bank_h2/scripts/logs/01_full_deploy/full_deploy.log"
echo -e "  ~/Documentos/GitHub/api_bank_h2/scripts/logs/despliegue/*.log"
echo -e "  Historial de commits Markdown:"
echo -e "  ~/Documentos/GitHub/api_bank_h2/scripts/logs/commits_hist.md"

echo -e "\n\033[1;33m🌐 VPS - Servicios:\033[0m"
echo -e "  /var/log/supervisor/coretransapi.err.log"
echo -e "  /var/log/nginx/error.log"
echo -e "  /var/log/nginx/access.log"

echo -e "\n\033[1;33m📢 Notificadores:\033[0m"
echo -e "  ~/.logs/notificador.log"
echo -e "  ~/.logs/notificador_30.log"

echo -e "\n\033[1;36m🧭 VER ALIAS RÁPIDOS:\033[0m"
echo -e "  \033[1;33mvps_logs_all\033[0m            Ver todos los logs críticos del VPS"
echo -e "  \033[1;33mvps_supervisor\033[0m          Solo errores del servicio supervisado"
echo -e "  \033[1;33mvps_nginx_all\033[0m           Errores + accesos de NGINX"
'
