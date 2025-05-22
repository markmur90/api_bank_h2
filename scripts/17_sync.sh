#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$BASE_DIR" || { echo "❌ No se pudo cambiar al directorio base $BASE_DIR"; exit 1; }

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env en $BASE_DIR"
  exit 1
fi

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

EXCLUDES=(
    "--exclude=.gitattributes"
    "--exclude=.git/"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    "--exclude=*.zip"
    "--exclude=*local.py"
    "--exclude=temp/"
    "--exclude=*.log"
    "--exclude=*.key"
    "--exclude=*.service"
    "--exclude=*.conf"
    "--exclude=*torrc"
    "--exclude=*.crt"
    "--exclude=*.key"
    "--exclude=*.sock"
)

actualizar_django_env() {
  local destino="$1"
  # local settings_path="$destino/config/settings/__init__.py"

  # if [[ ! -f "$settings_path" ]]; then
  #   log_error "No se encontró __init__.py para actualizar DJANGO_ENV en $destino."
  #   return
  # fi

#   python3 - <<EOF | tee -a "$LOG_FILE"
# import os
# settings_path = "$settings_path"
# try:
#     with open(settings_path, "r", encoding="utf-8") as f:
#         lines = f.readlines()
#     updated = False
#     new_lines = []
#     for line in lines:
#         if "DJANGO_ENV" in line and "os.getenv" in line:
#             import re
#             new_line = re.sub(r"['\"]local['\"]", "'production'", line)
#             if new_line != line:
#                 updated = True
#             new_lines.append(new_line)
#         else:
#             new_lines.append(line)
#     if updated:
#         with open(settings_path, "w", encoding="utf-8") as f:
#             f.writelines(new_lines)
#         print(f"✅ DJANGO_ENV actualizado a 'production' en {settings_path}.")
#     else:
#         print(f"⚠️ No se detectó DJANGO_ENV para actualizar en {settings_path}.")
# except Exception as e:
#     print(f"❌ Error al actualizar DJANGO_ENV en {settings_path}: {e}")
# EOF
}

log_info "🔁 Iniciando sincronización multi-entorno..."

DIR_PRODUCTION="$HOME/Documentos/GitHub/servers/production"
DIR_HEROKU="$HOME/Documentos/GitHub/servers/heroku"
DIR_API_BANK_HEROKU="$HOME/Documentos/GitHub/api_bank_heroku"
DIR_LOCAL="$HOME/Documentos/GitHub/servers/local"

for destino in "$DIR_PRODUCTION" "$DIR_HEROKU" "$DIR_LOCAL" "$DIR_API_BANK_HEROKU"; do
  if [[ ! -d "$destino" ]]; then
    log_error "El destino $destino no existe o no es accesible. Se omite."
    continue
  fi

  log_info "Iniciando sincronización hacia: $destino"
  echo -e "\033[7;30m🔄 Sincronizando archivos al destino: $destino\033[0m" | tee -a "$LOG_FILE"
  sudo rsync -av "${EXCLUDES[@]}" "$BASE_DIR/" "$destino/" | tee -a "$LOG_FILE"
  log_ok "Sincronización completada para $destino."

  cd "$destino" || { log_error "No se pudo cambiar al directorio $destino"; continue; }
  actualizar_django_env "$destino"
  cd "$BASE_DIR" || { log_error "No se pudo regresar al directorio base $BASE_DIR"; exit 1; }

  echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
done

log_ok "✅ Sincronización multi-entorno completada."

