#!/bin/bash
# port_scan.sh - Escaneo de puertos internos/expuestos

target="$1"
[ -z "$target" ] && echo "Uso: $0 <IP/host>" && exit 1

echo "🕵️ Escaneando $target..."
nmap -Pn -p 1-1024,3389,5900,8080 --open "$target" -oN portscan_$target.txt
echo "✅ Escaneo guardado en portscan_$target.txt"
