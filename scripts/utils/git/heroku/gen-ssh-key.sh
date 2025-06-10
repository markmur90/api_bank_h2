#!/usr/bin/env bash
set -euo pipefail

read -p "Introduce el nombre adicional para la clave (ej. empresa): " KEY_NAME
read -p "Introduce el correo electrónico: " EMAIL
read -p "Introduce un comentario: " COMMENT

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

KEY_PATH="$SSH_DIR/id_ed25519_${KEY_NAME}"
ssh-keygen -t ed25519 -C "${EMAIL} ${COMMENT}" -f "$KEY_PATH"

chmod 600 "$KEY_PATH"
chmod 644 "${KEY_PATH}.pub"

echo
echo "Clave pública generada en ${KEY_PATH}.pub:"
cat "${KEY_PATH}.pub"
