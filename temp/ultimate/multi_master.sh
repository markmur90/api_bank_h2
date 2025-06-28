#!/usr/bin/env bash
set -euo pipefail

# ============================== #
#     MULTI MASTER EXECUTION     #
# ============================== #

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR" || exit 1

echo "🛠️  Inicializando directorios y entornos (multi)..."
python3 -c "from config_master import init_directories; init_directories()"

LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_MASTER="$LOG_DIR/multi_master.log"

python3 -c "from config_master import init_directories; init_directories()"
# ============================== #
#         AYUDA --help           #
# ============================== #
# Si no se pasan argumentos, mostrar ayuda
if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Uso: $0 --envs=local,production [opciones para master.sh]"
  echo ""
  echo "Parámetros obligatorios:"
  echo "  --envs=ent1,ent2   Lista separada por comas de entornos definidos en .env"
  echo ""
  echo "Opciones disponibles (delegadas a master.sh):"
  echo "  -a     Ejecutar todos los scripts"
  echo "  -d     Diagnóstico del entorno"
  echo "  -r     Verificación de puertos"
  echo "  -c     Contenedores activos"
  echo "  -u     Actualización del sistema"
  echo "  -f     Firewall UFW"
  echo "  -m     Cambio MAC"
  echo "  -t     Inicio Tor"
  echo "  -k     Limpieza de backups"
  echo "  -p     Instalación PostgreSQL"
  echo "  -x     Reset de base de datos"
  echo "  -g     Migraciones Django"
  echo "  -s     Creación de superusuario"
  echo "  -l     Carga de fixtures"
  echo "  -e     Generación de claves PEM"
  echo "  -z     Backup comprimido"
  echo "  -b     Backup local"
  echo "  -y     Sincronización multientorno"
  echo "  -v     SSL + Supervisor + Nginx"
  echo "  -n     Ejecución Gunicorn"
  echo "  -h     Deploy Heroku"
  echo "  -j     Deploy Njalla"
  echo "  -o     Verificación por Tor"
  echo "  -q     Notificación final"
  echo "  -i     Subida de proyectos al VPS (rsync)"
  echo "  -w     Actualización DDNS Njalla"
  echo ""
  echo "📦 Ejemplos:"
  echo "  Ejecutar migraciones en local y producción:"
  echo "    $0 --envs=local,production -g"
  echo ""
  echo "  Ejecutar todo en heroku y local:"
  echo "    $0 --envs=heroku,local -a"
  echo ""
  exit 0
fi


# ============================== #
#   PARSEO DE ENTORNOS Y FLAGS   #
# ============================== #

ENV_LIST=""
POSITIONAL_ARGS=()

for arg in "$@"; do
  if [[ "$arg" == --envs=* ]]; then
    ENV_LIST="${arg#*=}"
  else
    POSITIONAL_ARGS+=("$arg")
  fi
done

if [[ -z "$ENV_LIST" ]]; then
  echo "❌ Debes especificar entornos con --envs=local,production"
  echo "Consulta con --help para más detalles."
  exit 1
fi

IFS=',' read -r -a ENTORNOS <<< "$ENV_LIST"

# ============================== #
#       EJECUCIÓN POR ENTORNO    #
# ============================== #

RESUMEN=()
TIEMPO_TOTAL_INICIO=$(date +%s)

for ENTORNO in "${ENTORNOS[@]}"; do
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "\n\033[1;35m==============================\033[0m"
  echo -e "🌍 Ejecutando entorno: \033[1;36m$ENTORNO\033[0m"
  echo -e "\033[1;35m==============================\033[0m"

  {
    echo ""
    echo "=============================="
    echo "⏱️  $TIMESTAMP - ENTORNO: $ENTORNO"
    echo "=============================="
  } >> "$LOG_MASTER"

  TIEMPO_INICIO=$(date +%s)

  if ./master.sh --env="$ENTORNO" "${POSITIONAL_ARGS[@]}" >> "$LOG_MASTER" 2>&1; then
    TIEMPO_FIN=$(date +%s)
    DURACION=$((TIEMPO_FIN - TIEMPO_INICIO))
    RESUMEN+=("✅ $ENTORNO — ${DURACION}s")
    echo -e "\033[1;32m✅ Completado: $ENTORNO (${DURACION}s)\033[0m"
  else
    TIEMPO_FIN=$(date +%s)
    DURACION=$((TIEMPO_FIN - TIEMPO_INICIO))
    RESUMEN+=("❌ $ENTORNO — Falló después de ${DURACION}s")
    echo -e "\033[1;31m❌ Falló: $ENTORNO (${DURACION}s)\033[0m"
  fi
done

# ============================== #
#          RESUMEN FINAL         #
# ============================== #

TIEMPO_TOTAL_FIN=$(date +%s)
DURACION_TOTAL=$((TIEMPO_TOTAL_FIN - TIEMPO_TOTAL_INICIO))

echo -e "\n\033[1;36m📋 RESUMEN DE EJECUCIÓN MULTIENTORNO:\033[0m"
for r in "${RESUMEN[@]}"; do
  echo "  $r"
done

echo -e "\n\033[1;35m⏱️  Tiempo total: ${DURACION_TOTAL}s\033[0m"
echo -e "\033[1;36m🗂️  Log maestro: $LOG_MASTER\033[0m\n"
