#!/usr/bin/env bash
set -e

confirmar() {
    echo ""
    echo ""
    printf "\033[1;34m🔷 ¿Confirmas la ejecución de: «%s»? (s/n):\033[0m " "$1"
    read -r resp
    [[ "$resp" == "s" || -z "$resp" ]]
}

clear

for PUERTO in 2222 8000 5000 8001 35729; do
    if lsof -i tcp:"$PUERTO" &>/dev/null; then
        if confirmar "Cerrar procesos en puerto $PUERTO"; then
            sudo fuser -k "${PUERTO}"/tcp || true
            echo -e "\033[7;30m✅ Puerto $PUERTO liberado con éxito.\033[0m"
        fi
    fi
done

if confirmar "Detener contenedores Docker activos"; then
    PIDS=$(docker ps -q)
    if [ -n "$PIDS" ]; then
        docker stop $PIDS
        echo -e "\033[7;30m🛑 Todos los contenedores Docker activos han sido detenidos.\033[0m"
        echo ""
    else
        echo -e "\033[8;30mℹ️ No se detectan contenedores Docker en ejecución.\033[0m"
        echo ""
    fi
    ALL_CONTAINERS=$(docker ps -a -q)
    if [ -n "$ALL_CONTAINERS" ]; then
        docker rm $ALL_CONTAINERS
        echo -e "\033[7;30m🗑️ Todos los contenedores Docker han sido eliminados.\033[0m"
        echo ""
    else
        echo -e "\033[8;30mℹ️ No hay contenedores Docker para eliminar.\033[0m"
        echo ""
    fi
    ALL_IMAGES=$(docker images -q)
    if [ -n "$ALL_IMAGES" ]; then
        docker rmi $ALL_IMAGES
        echo -e "\033[7;30m🗑️ Todas las imágenes Docker han sido eliminadas.\033[0m"
        echo ""
    else
        echo -e "\033[8;30mℹ️ No se encontraron imágenes Docker para eliminar.\033[0m"
        echo ""
    fi
fi

# Desactivar BuildKit para usar el builder clásico y evitar errores con docker-buildx
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0

echo ""
echo " Crear contenedor... "
docker-compose up --build -d
echo ""


echo "⏳ Esperando a que http://0.0.0.0:5000 esté disponible..."
until curl -s http://0.0.0.0:5000 >/dev/null; do
  sleep 1
done

URL="http://0.0.0.0:5000"
echo "✅ Servicio listo. Abriendo navegador en $URL"

if command -v xdg-open >/dev/null; then
  xdg-open "$URL"
elif command -v open >/dev/null; then
  open "$URL"
elif command -v start >/dev/null; then
  start "$URL"
else
  echo "⚠️ No encontré comando para abrir navegador. Por favor, accede manualmente a $URL"
fi
