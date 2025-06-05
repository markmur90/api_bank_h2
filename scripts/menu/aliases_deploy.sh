#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
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

BASE_DIR="$AP_H2_DIR"
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR='$SCRIPTS_DIR/backup'
CERTS_DIR='$SCRIPTS_DIR/certs'
DP_DJ_DIR='$SCRIPTS_DIR/deploy/django'
DP_GH_DIR='$SCRIPTS_DIR/deploy/github'
DP_HK_DIR='$SCRIPTS_DIR/deploy/heroku'
DP_VP_DIR='$SCRIPTS_DIR/deploy/vps'
SERVI_DIR='$SCRIPTS_DIR/service'
SYSTE_DIR='$SCRIPTS_DIR/src'
TORSY_DIR='$SCRIPTS_DIR/tor'
UTILS_DIR='$SCRIPTS_DIR/utils'
CO_SE_DIR='$UTILS_DIR/conexion_segura_db'
UT_GT_DIR='$UTILS_DIR/gestor-tareas'
SM_BK_DIR='$UTILS_DIR/simulator_bank'
TOKEN_DIR='$UTILS_DIR/token'
GT_GE_DIR='$UT_GT_DIR/gestor'
GT_NT_DIR='$UT_GT_DIR/notify'
GE_LG_DIR='$GT_GE_DIR/logs'
GE_SH_DIR='$GT_GE_DIR/scripts'


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
alias BKapi='cd "$AP_H2_DIR_BK" && source "$VENV_PATH" && clear && code .'
alias api_heroku='cd "$AP_HK_DIR" && source "$VENV_PATH" '
alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y'
alias monero='bash /opt/monero-gui/monero/monero-wallet-gui'


alias status_notify='bash "$GT_NT_DIR/"estado_notificadores.sh'
alias start_notify='bash "$GT_NT_DIR/"start_notificadores_interactivo.sh'
alias gest_notify='bash "$GT_NT_DIR/"gestionar_notificadores.sh'
alias restart_notify='bash "$GT_NT_DIR/"notificador_restart.sh'

alias gtareas_status='bash "$GE_SH_DIR/"gtareas_status.sh'

alias 000gtareas='nohup bash "$UT_GT_DIR/"deb/gestor_tareas/usr/local/bin/gestor_tareas.sh >/dev/null 2>&1 & disown'
alias 00gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_00.sh >/dev/null 2>&1 & disown'
alias 01gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_01.sh >/dev/null 2>&1 & disown'
alias 02gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_02.sh >/dev/null 2>&1 & disown'
alias 03gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_03.sh >/dev/null 2>&1 & disown'
alias 04gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_04.sh >/dev/null 2>&1 & disown'
alias 05gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_05.sh >/dev/null 2>&1 & disown'
alias 06gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_06.sh >/dev/null 2>&1 & disown'
alias 07gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_07.sh >/dev/null 2>&1 & disown'
alias 08gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_08.sh >/dev/null 2>&1 & disown'
alias 09gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_09.sh >/dev/null 2>&1 & disown'
alias 10gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_10.sh >/dev/null 2>&1 & disown'
alias 11gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_11.sh >/dev/null 2>&1 & disown'
alias 12gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_12.sh >/dev/null 2>&1 & disown'
alias 13gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_13.sh >/dev/null 2>&1 & disown'
alias 14gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_14.sh >/dev/null 2>&1 & disown'
alias 15gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_15.sh >/dev/null 2>&1 & disown'
alias 16gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_16.sh >/dev/null 2>&1 & disown'
alias 17gtareas='nohup bash "$GT_GE_DIR/"gestor_tareas_17.sh >/dev/null 2>&1 & disown'


# === VARIABLES ENTORNOS ===
unalias envAPP 2>/dev/null
envAPP() {source "$VENV_PATH" "$@"; }

alias api='cd "$AP_H2_DIR" && envAPP && clear '
alias deploy_full='bash "$SCRIPTS_DIR/menu/01_full.sh"'

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
alias vps_tor='vps_exec "sudo cat /var/lib/tor/hidden_service/hostname"'
alias tor_diag='vps_exec "bash "$TORSY_DIR/"check_torrc.sh"'
alias tor_newip='vps_exec "bash "$TORSY_DIR/"rotate_tor_ip.sh"'
alias tor_refresh='tor_diag && tor_newip'

alias sync_configs='vps_exec "bash "$DP_VP_DIR/"sync_configs_from_vps.sh"'
alias push_configs='vps_exec "bash "$DP_VP_DIR/"sync_configs_to_vps.sh"'




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
alias vps_locsync='bash $DP_VP_DIR/vps_sync.sh'
alias vps_up_copy='bash $DP_VP_DIR/vps_copy_up_files.sh'
alias vps_down_copy='bash $DP_VP_DIR/vps_copy_files.sh'

# === Sincronización por GitHub ===

alias vps_gitsync='bash $BACKU_DIR/00_14_sincronizacion_archivos.sh && bash ~/api_bank_h2/scripts/sync_local_and_vps.sh && api'

alias vps_logsync='
LOG_DIR=$(git rev-parse --show-toplevel 2>/dev/null || find "$PWD" -type f -name "manage.py" -exec dirname {} \; | head -n1)/scripts/logs/sync
[ -d "$LOG_DIR" ] && less "$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | head -n1)" || echo "❌ No hay logs de sincronización."
'



# ───📚 ALIAS DE AYUDA - MENÚ COMPLETO────────────────────────
alias d_hp_all='clear &&
log_info "📚 GUÍA COMPLETA DE ALIAS Y FUNCIONES"
d_hp_aliases && echo && d_hp_scripts && echo && d_hp_notif && echo && d_hp_logs && echo && d_hp_vps
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

alias d_hp_scripts='clear &&
log_info "📜 SCRIPTS DEL PROYECTO"
log_ok "01_full.sh                    → Script principal"
log_ok "00_16_01_subir_GitHub.sh     → Push a GitHub + Heroku"
log_ok "00_14_sincronizacion_archivos.sh → Sync estáticos"
log_ok "vps_sync.sh                  → Sync directo a VPS"
log_ok "sync_local_and_vps.sh        → Push + Pull remoto"
log_ok "00_24_sync_from_github.sh    → Pull en VPS + restart"
log_ok "diagnostico_entorno.sh       → Diagnóstico entorno"
log_ok "estado_notificadores.sh      → Estado notificadores"
log_ok "start_notificadores_interactivo.sh → Lanzador interactivo"
log_ok "gestionar_notificadores.sh   → Admin general de notificadores"
log_ok "notificador_restart.sh       → Reinicio notificadores"
'

alias d_hp_notif='clear &&
log_info "🔔 HERRAMIENTAS DE NOTIFICACIÓN"
log_ok "start_notify     → Inicia notificaciones (interactivo)"
log_ok "gest_notify      → Gestor interactivo de notificadores"
log_ok "proc_notify      → Lista procesos activos"
log_ok "restart_notify   → Reinicio general"
log_ok "5_notify         → Activa notificador 5m"
log_ok "30_notify        → Activa notificador 30m"
log_ok "5_stop           → Detiene notificador 5m"
log_ok "30_stop          → Detiene notificador 30m"
log_ok "gtareas_status   → Estado de gestor de tareas"
log_ok "000gtareas ... 17gtareas → Lanzadores paralelos de tareas"
'

alias d_hp_logs='clear &&
log_info "🪵 LOGS DISPONIBLES"
log_info "🔁 Sincronización"
log_ok "$SCRIPTS_DIR/logs/sync/*.log"
log_ok "vps_sync_lastlog → Último log"
log_info "📦 Despliegue y Push"
log_ok "$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"
log_ok "$SCRIPTS_DIR/logs/despliegue/*.log"
log_ok "$SCRIPTS_DIR/logs/commits_hist.md  → Historial de commits"
log_info "🌐 VPS - Servicios"
log_ok "/var/log/supervisor/coretransapi.err.log"
log_ok "/var/log/nginx/*.log"
log_info "🧭 Ver rápido"
log_ok "vps_logs_all, vps_supervisor, vps_nginx_all, vps_logsync"
'

alias d_hp_vps='clear &&
log_info "🌐 VPS & TOR"
log_ok "vps_tor        → Dirección onion"
log_ok "tor_diag       → Verifica config torrc"
log_ok "tor_newip      → Fuerza IP nueva"
log_ok "tor_refresh    → Diagnóstico + IP nueva"
log_info "📁 COPY FILES"
log_ok "vps_up_copy    → Sube archivos al VPS"
log_ok "vps_down_copy  → Baja archivos del VPS"
log_info "🔔 NOTIFICADORES"
log_ok "gtareas_status → Estado general"
log_ok "000gtareas ... 17gtareas → Lanzadores por ID"
log_info "📄 LOGS"
log_ok "vps_nginx_err / access / all"
log_ok "vps_logs_all / logsync / remote_check"
log_info "🛠️ COMANDOS"
log_ok "vps_reload / status / check / ping"
log_ok "vps_l_root / vps_l_user"
log_ok "pg_njalla_local → PostgreSQL desde local"
'
