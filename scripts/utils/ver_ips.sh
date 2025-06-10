#!/usr/bin/env bash
set -euo pipefail

echo "🌐 === DETECCIÓN DE IPs ==="

# IP local del PC
IP_LOCAL=$(hostname -I | awk '{print $1}')
echo "💻 IP LOCAL del equipo: $IP_LOCAL"

# IP pública del VPS (si aplica)
echo -n "🌍 IP PÚBLICA (externa): "
curl -s ifconfig.me || echo "No disponible"

# Contenedores Docker en ejecución
echo -e "\n🐳 Docker Containers IPs:"
docker ps --format "table {{.Names}}	{{.Status}}" 

for container in $(docker ps -q); do
    NAME=$(docker inspect --format='{{.Name}}' "$container" | cut -c2-)
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
    echo " - $NAME → $IP"
done

echo "✅ Listo."