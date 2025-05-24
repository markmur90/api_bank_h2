#!/bin/bash
set -e

echo "🔐 Iniciando configuración básica para VPS: coretransapi"
scp -i "$HOME/.ssh/vps_njalla_ed25519" ~/.ssh/vps_njalla_ed25519.pub root@80.78.30.188:/root/coretransapi.pub
ssh -i "$HOME/.ssh/vps_njalla_ed25519" root@80.78.30.188 'bash -s' < scripts/vps_instalar_dependencias.sh
