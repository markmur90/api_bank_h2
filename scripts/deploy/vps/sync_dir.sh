#!/usr/bin/env bash
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
AP_SM_DIR="/home/markmur88/Simulador"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
EXCLUDES="$SCRIPTS_DIR/deploy/vps/excludes.txt"
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
VPS_BASE_DIR="/home/markmur88/api_bank_h2"
VPS_HK_DIR="/home/markmur88/api_bank_heroku"
VPS_SM_DIR="/home/markmur88/Simulador"
VPS_VENV_PATH="/home/markmur88/envAPP"
LOG_DIR="$SCRIPTS_DIR/logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync.log"
SUDOPWD="Ptf8454Jd55"
set -euo pipefail
SUDOPWD="Ptf8454Jd55"

sync_project() {
  local name="$1" local local_dir="$2" local remote_dir="$3"
  echo "🆕 [$name] Proyecto local: $local_dir" | tee -a "$LOG_FILE"
  echo "🧹 [$name] Eliminando patrones excluidos en VPS..." | tee -a "$LOG_FILE"
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    echo "🗑 [$name] Borrando: $pattern" | tee -a "$LOG_FILE"
    ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "rm -rf '$remote_dir/$pattern'" >>"$LOG_FILE" 2>&1
  done <"$EXCLUDES"
  echo "🔄 [$name] Iniciando rsync local→VPS..." | tee -a "$LOG_FILE"
  rsync -avz --delete \
    --exclude-from="$EXCLUDES" \
    -e "ssh -i $SSH_KEY -p $VPS_PORT" \
    "$local_dir/" "$VPS_USER@$VPS_IP:$remote_dir" \
    | tee -a "$LOG_FILE"
  echo "✅ [$name] Sincronización completada." | tee -a "$LOG_FILE"
}

sync_project "H2" "$AP_H2_DIR" "$VPS_BASE_DIR"
sync_project "HK" "$AP_HK_DIR" "$VPS_HK_DIR"
sync_project "SM" "$AP_SM_DIR" "$VPS_SM_DIR"

echo "📡 Ejecutando comandos remotos en el VPS..." | tee -a "$LOG_FILE"
ssh -tt -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" \
"SUDOPWD='$SUDOPWD'; export TERM=xterm; set -euo pipefail;
 sleep3
 echo ""
 echo '🌐 Entrando en directorio remoto: $VPS_HK_DIR';
 cd '$VPS_HK_DIR';
 echo '🔧 Activando entorno virtual en VPS: $VPS_HK_DIR';
 source '$VPS_VENV_PATH/bin/activate';
 echo '🔁 Ejecutando script 01_full.sh en VPS';
 bash ~/api_bank_h2/scripts/menu/01_full.sh -Q -I;
 sleep3
 echo ""
 echo '🔁 Reiniciando servicios en VPS...';
 echo \"\$SUDOPWD\" | sudo -S supervisorctl status | grep -q '^coretransapi' && {
   echo \"\$SUDOPWD\" | sudo -S supervisorctl restart coretransapi;
   echo \"📋 Estado del servicio coretransapi en VPS:\";
   echo \"\$SUDOPWD\" | sudo -S supervisorctl status coretransapi;
   echo \"📄 Últimos logs de error en VPS:\";
   echo \"\$SUDOPWD\" | sudo -S tail -n 10 /var/log/supervisor/coretransapi.err.log;
 } || {
   echo '⚠️ Servicio coretransapi no está registrado en supervisor. Saltando reinicio...';
 };
 sleep3
 echo ""
 echo \"\$SUDOPWD\" | sudo -S systemctl reload nginx;
 echo '✅ Comandos remotos completados.'"
echo "🎉 Todo listo, sincronizaciones y despliegue en VPS finalizados." | tee -a "$LOG_FILE"
 sleep3
 echo ""