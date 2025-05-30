#!/bin/bash
set -e

echo "🎯 Hostname y zona horaria..."
hostnamectl set-hostname coretransapi
echo "coretransapi" > /etc/hostname
timedatectl set-timezone Europe/Madrid

echo "👤 Usuario markmur88..."
useradd -m -s /bin/bash markmur88
usermod -aG sudo markmur88
echo "markmur88 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/markmur88
