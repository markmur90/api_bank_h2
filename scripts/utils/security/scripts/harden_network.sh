#!/bin/bash
# harden_network.sh - Refuerza reglas básicas de red

echo "🔐 Endureciendo configuración de red..."
# Desactiva respuesta a ping
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all

# Desactiva redirección IP
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects

# Reglas básicas con iptables
iptables -P INPUT DROP
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # Solo si se necesita SSH

echo "✅ Red endurecida (considerar persistencia con iptables-save)"
