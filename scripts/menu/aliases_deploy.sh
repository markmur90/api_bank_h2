#!/usr/bin/env bash

# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
BACKUPDIR="/home/markmur88/backup"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"


# === VARIABLES VPS (personalizables) ===
export VPS_USER="markmur88"
export VPS_IP="80.78.30.242"
export VPS_PORT="22"
export SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
export VPS_SSH_KEY="/home/markmur88/.ssh/id_ed25519"
export VPS_API_DIR="/home/markmur88/api_bank_heroku"

ssh-add ~/.ssh/id_ed25519 && ssh-add ~/.ssh/vps_njalla_nueva

# === FUNCIÓN AUXILIAR ===
vps_exec() {
    clear && api && ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "$@"
}

# ───🎨 COLORES Y FUNCIONES DE LOG────────────────────────────
RESET='\033[0m'
AMARILLO='\033[1;33m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
AZUL='\033[1;34m'

log_info()  { echo -e "\n${AZUL} $1${RESET}"; }
log_ok()    { echo -e "${VERDE}-   $1${RESET}"; }
log_error() { echo -e "${ROJO}[ERR]  $1${RESET}"; }


# === ACCESOS DIRECTOS AL PROYECTO ===

alias freedom='cd "/home/markmur88/FreedomGPT" && source "/home/markmur88/venvAPI/bin/activate" && clear '
alias BKapi='cd "$AP_BK_DIR" && source "$VENV_PATH" && clear && code .'
alias api_heroku='cd "$AP_HK_DIR" && source "$VENV_PATH" '
alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y'
alias monero='bash /opt/monero-gui/monero/monero-wallet-gui'


alias status_notify='bash $GT_NT_DIR/estado_notificadores.sh'
alias start_notify='bash $GT_NT_DIR/start_notificadores_interactivo.sh'
alias gest_notify='bash $GT_NT_DIR/gestionar_notificadores.sh'
alias restart_notify='bash $GT_NT_DIR/notificador_restart.sh'
alias notificador='nohup bash $GT_NT_DIR/notificador.sh >/dev/null 2>&1 & disown'

alias gtareas_status='bash $GE_SH_DIR/gtareas_status.sh'
alias gtareas_stop='bash $GE_SH_DIR/detener_tareas.sh'
alias 000gtareas='nohup bash $UT_GT_DIR/deb/gestor_tareas/usr/local/bin/gestor_tareas.sh >/dev/null 2>&1 & disown'
alias 00gtareas='nohup bash $GE_SH_DIR/gestor_tareas_00.sh >/dev/null 2>&1 & disown'
alias 01gtareas='nohup bash $GE_SH_DIR/gestor_tareas_01.sh >/dev/null 2>&1 & disown'
alias 02gtareas='nohup bash $GE_SH_DIR/gestor_tareas_02.sh >/dev/null 2>&1 & disown'
alias 03gtareas='nohup bash $GE_SH_DIR/gestor_tareas_03.sh >/dev/null 2>&1 & disown'
alias 04gtareas='nohup bash $GE_SH_DIR/gestor_tareas_04.sh >/dev/null 2>&1 & disown'
alias 05gtareas='nohup bash $GE_SH_DIR/gestor_tareas_05.sh >/dev/null 2>&1 & disown'
alias 06gtareas='nohup bash $GE_SH_DIR/gestor_tareas_06.sh >/dev/null 2>&1 & disown'
alias 07gtareas='nohup bash $GE_SH_DIR/gestor_tareas_07.sh >/dev/null 2>&1 & disown'
alias 08gtareas='nohup bash $GE_SH_DIR/gestor_tareas_08.sh >/dev/null 2>&1 & disown'
alias 09gtareas='nohup bash $GE_SH_DIR/gestor_tareas_09.sh >/dev/null 2>&1 & disown'
alias 10gtareas='nohup bash $GE_SH_DIR/gestor_tareas_10.sh >/dev/null 2>&1 & disown'
alias 11gtareas='nohup bash $GE_SH_DIR/gestor_tareas_11.sh >/dev/null 2>&1 & disown'
alias 12gtareas='nohup bash $GE_SH_DIR/gestor_tareas_12.sh >/dev/null 2>&1 & disown'
alias 13gtareas='nohup bash $GE_SH_DIR/gestor_tareas_13.sh >/dev/null 2>&1 & disown'
alias 14gtareas='nohup bash $GE_SH_DIR/gestor_tareas_14.sh >/dev/null 2>&1 & disown'
alias 15gtareas='nohup bash $GE_SH_DIR/gestor_tareas_15.sh >/dev/null 2>&1 & disown'
alias 16gtareas='nohup bash $GE_SH_DIR/gestor_tareas_16.sh >/dev/null 2>&1 & disown'
alias 17gtareas='nohup bash $GE_SH_DIR/gestor_tareas_17.sh >/dev/null 2>&1 & disown'


# === VARIABLES ENTORNOS ===
unalias envAPP 2>/dev/null
envAPP() {source "$VENV_PATH" "$@"; }

alias api="cd $AP_H2_DIR && envAPP"
alias deploy_full='api && bash "$SCRIPTS_DIR/menu/01_full.sh"'

alias d_help='api && deploy_full --help'
alias d_step='api && deploy_full -s'
alias d_all='api && deploy_full -a'
alias d_debug='api && deploy_full -d'
alias d_menu='api && deploy_full --menu'
alias d_status='api && bash $SERVI_DIR/diagnostico_entorno.sh'

alias d_Gsync='api && deploy_full -S -Gi'


# === VARIABLES ENTORNOS ===

unalias d_local 2>/dev/null
d_local() {api && deploy_full --env=local -Z -C -S -Q -I -l "$@"; }
unalias d_heroku 2>/dev/null
d_heroku() {api && deploy_full --env=production -Z -C -S -Q -I -l -H -B "$@"; }
unalias d_njalla 2>/dev/null
d_njalla() {api && deploy_full --env=production -Y -P -D -M -x -Z -C -S -Q -I -l -Gi "$@"; }


# === VARIABLES LOCALES ===
unalias d_mig 2>/dev/null
d_mig() {python3 manage.py makemigrations && python3 manage.py migrate && python3 manage.py collectstatic --noinput && clear}


# === VARIABLES API ===
unalias d_pgm 2>/dev/null
d_pgm() {api && deploy_full -Q -I -l "$@"; }
unalias d_hek 2>/dev/null
d_hek() {api && deploy_full -B -H "$@"; }
unalias d_back 2>/dev/null
d_back() {api && deploy_full -C -Z "$@"; }
unalias d_sys 2>/dev/null
d_sys() {api && deploy_full -Y -P -D -M -x "$@"; }
unalias d_cep 2>/dev/null
d_cep() {api && deploy_full -p -E "$@"; }
unalias d_vps 2>/dev/null
d_vps() {d_env && deploy_full -v "$@"; }


# === TOR ===
alias vps_tor='api && vps_exec "sudo cat /var/lib/tor/hidden_service/hostname"'
alias tor_diag='api && vps_exec "bash $TORSY_DIR/check_torrc.sh"' 
alias tor_newip='api && vps_exec "bash $TORSY_DIR/rotate_tor_ip.sh"' 
alias tor_refresh='api && tor_diag && tor_newip'

alias sync_configs='vps_exec "bash $DP_VP_DIR/sync_configs_from_vps.sh"'
alias push_configs='vps_exec "bash $DP_VP_DIR/sync_configs_to_vps.sh"'

alias sim_bank_ins='vps_exec "bash $SM_BK_DIR/instalar_simulador.sh"' 
alias sim_bank_chk='vps_exec "bash $SM_BK_DIR/check_tor_simulator.sh"' 
alias sim_bank_mon='vps_exec "bash $SM_BK_DIR/monitor_logs.sh"' 
alias sim_bank_ges='vps_exec "bash $SM_BK_DIR/gestor_simulador.sh"' 
alias sim_bank_ping="torsocks curl --silent --fail http://\$(vps_exec 'cat /var/lib/tor/hidden_service/hostname') || echo '[ERROR] No se pudo conectar al servicio oculto'"
alias sim_bank_ping_d="torsocks curl --silent --fail http://\$(vps_exec 'cat /var/lib/tor/hidden_service/hostname') | grep -qi 'django' && echo '[OK] Servicio oculto responde con Django' || echo '[ERROR] No se detectó Django en la respuesta'"
alias sync_onion='bash ~/api_bank_h2/scripts/utils/simulator_bank/sync_onion_local.sh'
alias sim_fix_logs='vps_exec "bash \"$SM_BK_DIR/fix_sim_logs.sh\""' 


# ─── 📦 Logs del sistema ────────────────────────────────
alias vps_supervisor='vps_exec "tail -f /var/log/supervisor/coretransapi.err.log"'

# ─── 🌐 Logs de NGINX ──────────────────────────────────
alias vps_nginx_err='vps_exec "tail -f /var/log/nginx/error.log"'
alias vps_nginx_access='vps_exec "tail -f /var/log/nginx/access.log"'
alias vps_nginx_all='vps_exec "tail -f /var/log/nginx/error.log /var/log/nginx/access.log"'

# 🪵 Todos los logs críticos juntos
alias vps_logs_all='vps_exec "tail -f /var/log/supervisor/coretransapi.err.log /var/log/nginx/error.log /var/log/nginx/access.log"'



alias vps_remote_check='bash $DP_VP_DIR/vps_remote_check.sh'

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
alias vps_locsycl='bash $DP_VP_DIR/vps_sync_clean.sh'
alias vps_locsync='bash $DP_VP_DIR/vps_sync.sh'
alias vps_up_copy='bash $DP_VP_DIR/vps_copy_up_files.sh'
alias vps_down_copy='bash $DP_VP_DIR/vps_copy_files.sh'
alias vps_restart='bash ~/api_bank_h2/scripts/utils/simulator_bank/reiniciar_servicios.sh'

# === Sincronización por GitHub ===

alias vps_gitsync='bash $BACKU_DIR/00_14_sincronizacion_archivos.sh && bash $DP_VP_DIR/sync_local_and_vps.sh && api'

# Logs de sincronización
alias log_sync_last='less "$(ls -1t $SCRIPTS_DIR/logs/sync/*.log 2>/dev/null | head -n1)"'

# Logs de despliegue general
alias log_deploy='less "$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"'

# Logs de despliegue individuales
alias log_push='less "$SCRIPTS_DIR/logs/despliegue/00_16_01_subir_GitHub.log"'
alias log_sync_arch='less "$SCRIPTS_DIR/logs/despliegue/00_14_sincronizacion_archivos.log"'

# Historial de commits
alias log_commits='less "$SCRIPTS_DIR/logs/commits_hist.md"'

# Logs del VPS
alias log_vps_supervisor='vps_exec "tail -f /var/log/supervisor/coretransapi.err.log"'
alias log_vps_nginx_err='vps_exec "tail -f /var/log/nginx/error.log"'
alias log_vps_nginx_acc='vps_exec "tail -f /var/log/nginx/access.log"'
alias log_vps_all='vps_exec "tail -f /var/log/supervisor/coretransapi.err.log /var/log/nginx/error.log /var/log/nginx/access.log"'

NOTIF_DIR="/home/markmur88/notas"
TG_CONF_SCRIPT="$NOTIF_DIR/telegram_config.sh"

# Alias para configurar Telegram
alias tg_bot_conf='bash "$TG_CONF_SCRIPT"'


# ───📚 ALIAS DE AYUDA - MENÚ COMPLETO────────────────────────
alias d_hp_all='clear &&
log_info "📚 GUÍA COMPLETA DE AYUDA DISPONIBLE"
log_ok "d_hp_aliases    → Alias generales y comandos del entorno"
log_ok "d_hp_notif      → Gestión de notificadores y tareas"
log_ok "d_hp_logs       → Visualización de logs locales y VPS"
log_ok "d_hp_vps        → Comandos y utilidades para VPS + TOR"
'

alias d_hp_notif='clear &&
log_info "🔔 HERRAMIENTAS DE NOTIFICACIÓN"
log_ok "start_notify     → Inicia notificaciones (interactivo)"
log_ok "gest_notify      → Gestor interactivo de notificadores"
log_ok "gtareas_status   → Estado de gestor de tareas"
log_ok "000gtareas       → Lanzador de tareas paralelas"
log_ok "00gtareas        → Lanzador de tareas paralelas"
log_ok "01gtareas        → Lanzador de tareas paralelas"
log_ok "02gtareas        → Lanzador de tareas paralelas"
log_ok "03gtareas        → Lanzador de tareas paralelas"
log_ok "04gtareas ... 17gtareas → Otros lanzadores de tareas"
'


alias d_hp_aliases='clear &&
log_info "🧰 ALIAS GENERALES DISPONIBLES"
log_ok "api               → Accede al proyecto principal"
log_ok "freedom           → Entra a FreedomGPT"
log_ok "BKapi             → Backup + VSCode"
log_ok "api_heroku        → Acceso Heroku del proyecto"
log_ok "update            → Actualiza todo el sistema"
log_ok "monero            → Lanza GUI de Monero"
log_ok "d_local           → Despliegue local completo"
log_ok "d_heroku          → Despliegue a Heroku"
log_ok "d_njalla          → Despliegue a VPS Njalla"
log_ok "d_env             → Activa entorno virtual"
log_ok "d_mig             → Migraciones + estáticos"
log_ok "d_pgm             → Setup DB y datos"
log_ok "d_hek             → Deploy Heroku"
log_ok "d_back            → Backup general"
log_ok "d_sys             → Ajustes de sistema VPS"
log_ok "d_cep             → Certificados SSL"
log_ok "d_vps             → Post-deploy VPS"
'

alias d_hp_logs='clear &&
log_info "🪵 LOGS DISPONIBLES"
log_info "🔁 Sincronización"
log_ok "log_sync_last                           → Último log de sincronización"
log_info "📦 Despliegue y Push"
log_ok "log_deploy                              → Log de full deploy"
log_ok "log_push                                → Log de push a GitHub"
log_ok "log_sync_arch                           → Log de sincronización de archivos"
log_ok "log_commits                             → Historial de commits"
log_info "🌐 VPS - Servicios"
log_ok "log_vps_supervisor                      → Logs de supervisor"
log_ok "log_vps_nginx_err                       → Logs de error NGINX"
log_ok "log_vps_nginx_acc                       → Logs de acceso NGINX"
log_ok "log_vps_all                             → Todos los logs críticos del VPS"
'



alias d_hp_vps='clear &&
log_info "🌐 VPS & TOR"
log_ok "vps_tor        → Dirección onion"
log_ok "tor_diag       → Verifica config torrc"
log_ok "tor_newip      → Fuerza IP nueva"
log_ok "tor_refresh    → Diagnóstico + IP nueva"
log_info "📁 COPY FILES"
log_ok "vps_locsycl    → Sube archivos al VPS de los 3 directorios"
log_ok "vps_locsync    → Sube archivos al VPS"
log_ok "vps_up_copy    → Sube archivos al VPS"
log_ok "vps_down_copy  → Baja archivos del VPS"
log_ok "vps_restart  → Baja archivos del VPS"
log_info "🔔 NOTIFICADORES"
log_ok "gtareas_status → Estado general"
log_ok "000gtareas ... 17gtareas → Lanzadores por ID"
log_info "📄 SIMULADOR"
log_ok "sim_bank_ins   → Instala Simulador al VPS"
log_ok "sim_bank_chk   → Chequea Simulador del VPS"
log_ok "sim_fix_logs   → Chequea Simulador del VPS"
log_ok "sync_onion   → Chequea Simulador del VPS"
log_ok "sim_bank_mon   → Monitorea Simulador del VPS"
log_ok "sim_bank_ges   → Gestiona Simulador del VPS"
log_ok "sim_bank_ping   → Gestiona Simulador del VPS"
log_ok "sim_bank_ping_d   → Gestiona Simulador del VPS"
log_info "🛠️ COMANDOS"
log_ok "vps_reload / status / check / ping"
log_ok "vps_l_root / vps_l_user"
log_ok "pg_njalla_local → PostgreSQL desde local"
'
