#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Limpieza de backups ZIP/SQL antiguos
# ===========================

# Cargar entorno desde .env
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

# Preparar log
mkdir -p "$LOG_DIR" "$BACKUP_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "🧹 Iniciando limpieza de backups antiguos..."

cd "$BACKUP_DIR"

mapfile -t files < <(ls -1tr *.zip *.sql 2>/dev/null || true)

declare -A first last all keep
for f in "${files[@]}"; do
    d=${f:10:8}  # Extrae fecha del nombre
    all["$d"]+="$f;"
    [[ -z "${first[$d]:-}" ]] && first[$d]=$f
    last[$d]=$f
done

today=$(date +%Y%m%d)

# Mantener el primero y último de cada día
for d in "${!first[@]}"; do keep["${first[$d]}"]=1; done
for d in "${!last[@]}";  do keep["${last[$d]}"]=1;  done

# Mantener los 10 más recientes del día actual
today_files=()
for f in "${files[@]}"; do
    [[ "${f:10:8}" == "$today" ]] && today_files+=("$f")
done
n=${#today_files[@]}
s=$(( n > 10 ? n - 10 : 0 ))
for ((i=s; i<n; i++)); do
    keep["${today_files[i]}"]=1
done

# Eliminar archivos que no están en la lista de conservación
for f in "${files[@]}"; do
    if [[ -z "${keep[$f]:-}" ]]; then
        rm -f "$f" && echo -e "\033[7;30m🗑️ Eliminado $f.\033[0m" | tee -a "$LOG_FILE"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    fi
done

cd - > /dev/null

log_ok "✅ Limpieza de backups completada."

