#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="./cuenta.config"
touch "$CONFIG_FILE"
chmod 600 "$CONFIG_FILE"

navigate_folder() {
  HOME_DIR="$HOME"
  current_dir_local="$HOME_DIR"
  while true; do
    echo
    echo "🗂 Directorio local actual: $current_dir_local"
    echo "   0) [Seleccionar ESTA carpeta: $(basename "$current_dir_local")]"
    idx=1
    if [ "$current_dir_local" != "$HOME_DIR" ]; then
      echo "   $idx) ../"
      ((idx++))
    fi
    mapfile -t local_dirs < <(find "$current_dir_local" -maxdepth 1 -mindepth 1 -type d | sort)
    for d in "${local_dirs[@]}"; do
      echo "   $idx) $(basename "$d")/"
      ((idx++))
    done
    echo "   $idx) Otra ruta manual"
    read -rp "➡️ Ingresa el número (ej: 0, 1, 2, ...): " choice_local
    if ! [[ "$choice_local" =~ ^[0-9]+$ ]]; then
      echo "❌ Entrada inválida. Debe ser un número."
      continue
    fi
    max_local=$(( idx - 1 ))
    if (( choice_local < 0 || choice_local > max_local )); then
      echo "❌ Número fuera de rango (0 a $max_local)."
      continue
    fi
    if (( choice_local == 0 )); then
      FOLDER_PATH="$current_dir_local"
      break
    fi
    if [ "$current_dir_local" != "$HOME_DIR" ]; then
      if (( choice_local == 1 )); then
        current_dir_local="$(dirname "$current_dir_local")"
        continue
      else
        opt_local=1
      fi
    else
      opt_local=0
    fi
    sub_idx_local=$(( choice_local - 1 - opt_local + 1 ))
    real_idx_local=$(( sub_idx_local - 1 ))
    if (( real_idx_local >= 0 && real_idx_local < ${#local_dirs[@]} )); then
      current_dir_local="${local_dirs[$real_idx_local]}"
    else
      echo "❌ Opción no válida."
    fi
  done
}

navigate_ssh() {
  HOME_DIR="$HOME/.ssh"
  [ -d "$HOME_DIR" ] || HOME_DIR="$HOME"
  current_dir_ssh="$HOME_DIR"
  while true; do
    echo
    echo "🔑 Directorio SSH actual: $current_dir_ssh"
    echo "   0) [Seleccionar ESTA carpeta: $(basename "$current_dir_ssh")]"
    idx=1
    if [ "$current_dir_ssh" != "$HOME_DIR" ]; then
      echo "   $idx) ../"
      ((idx++))
    fi
    mapfile -t ssh_files < <(find "$current_dir_ssh" -maxdepth 1 -mindepth 1 -type f ! -name "*.pub" | sort)
    for f in "${ssh_files[@]}"; do
      echo "   $idx) $(basename "$f")"
      ((idx++))
    done
    echo "   $idx) Otra ruta manual"
    read -rp "➡️ Ingresa el número (ej: 0, 1, 2, ...): " choice_ssh
    if ! [[ "$choice_ssh" =~ ^[0-9]+$ ]]; then
      echo "❌ Entrada inválida. Debe ser un número."
      continue
    fi
    max_ssh=$(( idx - 1 ))
    if (( choice_ssh < 0 || choice_ssh > max_ssh )); then
      echo "❌ Número fuera de rango (0 a $max_ssh)."
      continue
    fi
    if (( choice_ssh == 0 )); then
      SSH_KEY="$current_dir_ssh"
      break
    fi
    if [ "$current_dir_ssh" != "$HOME_DIR" ]; then
      if (( choice_ssh == 1 )); then
        current_dir_ssh="$(dirname "$current_dir_ssh")"
        continue
      else
        opt_ssh=1
      fi
    else
      opt_ssh=0
    fi
    sub_idx_ssh=$(( choice_ssh - 1 - opt_ssh + 1 ))
    real_idx_ssh=$(( sub_idx_ssh - 1 ))
    if (( real_idx_ssh >= 0 && real_idx_ssh < ${#ssh_files[@]} )); then
      SSH_KEY="${ssh_files[$real_idx_ssh]}"
      break
    else
      echo "❌ Opción no válida."
    fi
  done
}

if ! grep -q '^FOLDER_PATH=' "$CONFIG_FILE"; then
  navigate_folder
  echo "FOLDER_PATH=\"$FOLDER_PATH\"" >> "$CONFIG_FILE"
else
  eval "$(grep -m1 '^FOLDER_PATH=' "$CONFIG_FILE")"
fi

if ! grep -q '^SSH_KEY=' "$CONFIG_FILE"; then
  navigate_ssh
  echo "SSH_KEY=\"$SSH_KEY\"" >> "$CONFIG_FILE"
else
  eval "$(grep -m1 '^SSH_KEY=' "$CONFIG_FILE")"
fi

load_or_prompt() {
  name="$1"; prompt="$2"
  if ! grep -q "^${name}=" "$CONFIG_FILE"; then
    read -rp "$prompt" val
    echo "${name}=\"${val}\"" >> "$CONFIG_FILE"
    eval "${name}=\"${val}\""
  else
    eval "$(grep -m1 "^${name}=" "$CONFIG_FILE")"
  fi
}

load_or_prompt REPO_URL   "URL SSH del repositorio: "
load_or_prompt BRANCH     "Rama a usar: "
load_or_prompt COMMIT_MSG "Mensaje para el commit: "

if ! grep -q '^CRON_SCHEDULE=' "$CONFIG_FILE"; then
  echo "Selecciona intervalo de sincronización en minutos:"
  PS3="Opción: "
  opciones=("5" "10" "15" "30" "45" "60")
  select opt in "${opciones[@]}"; do
    case $opt in
      5)  schedule="*/5 * * * *"; break ;;
      10) schedule="*/10 * * * *"; break ;;
      15) schedule="*/15 * * * *"; break ;;
      30) schedule="*/30 * * * *"; break ;;
      45) schedule="*/45 * * * *"; break ;;
      60) schedule="0 * * * *";   break ;;
      *) echo "Opción inválida"; continue ;;
    esac
  done
  echo "CRON_SCHEDULE=\"$schedule\"" >> "$CONFIG_FILE"
  SCRIPT_PATH="$(realpath "$0")"
  ( crontab -l 2>/dev/null; echo "$schedule $SCRIPT_PATH" ) | crontab -
else
  eval "$(grep -m1 '^CRON_SCHEDULE=' "$CONFIG_FILE")"
fi

FILES=("$@")
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

REPO_DIR="$FOLDER_PATH/repos/$(basename "${REPO_URL%.git}")"
mkdir -p "$FOLDER_PATH/repos"
if [ ! -d "$REPO_DIR" ]; then
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"
git remote set-url origin "$REPO_URL"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"
if [ "${#FILES[@]}" -eq 0 ]; then
  git add .
else
  git add "${FILES[@]}"
fi
git commit -m "$COMMIT_MSG"
git push origin "$BRANCH"

LOG_FILE="$FOLDER_PATH/sync_log.md"
if [ ! -f "$LOG_FILE" ]; then
  echo "# Registro de sincronizaciones" > "$LOG_FILE"
fi
echo "- $(date '+%Y-%m-%d %H:%M:%S'): Sincronizada rama $BRANCH del repositorio $REPO_URL" >> "$LOG_FILE"
