#!/bin/bash

echo "🔁 Reiniciando entorno Ghost Recon..."

# Cambiar MAC
echo "🔧 Cambiando MAC..."
sudo ip link set dev eth0 down
sudo macchanger -r eth0
sudo ip link set dev eth0 up

# Reiniciar Tor
echo "🌀 Reiniciando Tor..."
sudo service tor restart
sleep 5

# Limpiar logs antiguos (manteniendo estructura)
echo "🧹 Limpiando logs y capturas antiguas..."
rm -rf logs/*
rm -rf capturas/*

# Ejecutar ghost_recon
echo "👻 Ejecutando ghost_recon_ultimate.py..."
python3 ghost_recon_ultimate.py "$@"
