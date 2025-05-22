#!/usr/bin/env bash
set -euo pipefail

PROMPT_MODE=true
OMIT_GUNICORN=false


PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2_H"
BACKUP_DIR="$HOME/Documentos/GitHub/backup"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
VENV_PATH="$HOME/Documentos/Entorno/venvAPI"
INTERFAZ="wlan0"

DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"

# === OPCIONES DISPONIBLES PARA ./01_full.sh ===
# -a  --all                Ejecuta todo sin confirmaciones interactivas
# -s  --step               Modo paso a paso (requiere confirmar cada paso)
# -B  --omit-bdd           Omite sincronización de la base de datos remota
# -H  --omit-heroku        Omite sincronización o deploy en Heroku
# -G  --omit-gunicorn      Omite reinicio del servidor Gunicorn
# -L  --omit-local         Omite generación de respaldos JSON locales
# -W  --omit-web           Omite generación de respaldos JSON web
# -S  --omit-sync          Omite sincronización de respaldos locales
# -Z  --omit-zip           Omite creación de archivo ZIP del respaldo SQL
# -U  --omit-create-user   Omite creación del usuario
# -l  --omit-load-local    Omite carga de respaldo local
# -w  --omit-load-web      Omite carga de respaldo web
# -M  --omit-mac           Omite comandos específicos para macOS
# -C  --omit-clean         Omite limpieza de archivos temporales

# === COMBINACIONES RECOMENDADAS ===
# ./01_full.sh -a                           # Todo automático
# ./01_full.sh -a -W -L -Z                  # Todo excepto respaldos
# ./01_full.sh -a -U -w                     # Sin creación de usuario ni carga web
# ./01_full.sh -s -B -H -G                  # Modo paso a paso sin despliegue remoto
# ./01_full.sh -a -H -C -G -W -Z -U         # Desarrollo local, sin deploy ni limpieza
# ./01_full.sh -a -H -G -U -W               # Solo sincronizar y cargar backups locales
# ./01_full.sh -a -W -L                     # Solo compresión y carga sin generar respaldos
# ./01_full.sh -a -H -C -G -W -Z -U         # Desarrollo local sin limpieza ni despliegue
# ./01_full.sh -a -L -l -W -U               # Solo pruebas sin tocar backups ni usuarios:



mkdir -p "$BACKUP_DIR"

function usage() {
    echo "Uso: $0 [opciones]"
    echo
    echo "Opciones:"
    echo "  -a, --all                   Ejecuta todos los pasos automáticamente"
    echo "  -s, --step                  Ejecuta paso a paso con confirmación"
    echo "  -G, --omit-gunicorn         Omitir arranque del servidor Gunicorn"
    echo "  -h, --help                  Mostrar esta ayuda y salir"
    echo
}
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all) PROMPT_MODE=false; shift ;;
        -s|--step) PROMPT_MODE=true; shift ;;
        -G|--omit-gunicorn) OMIT_GUNICORN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Opción desconocida: $1"; usage; exit 1 ;;
    esac
done

confirmar() {
    [[ "$PROMPT_MODE" == false ]] && return 0
    echo
    printf "\033[1;34m🔷 ¿Confirmas: %s? (s/n):\033[0m " "$1"
    read -r resp
    [[ "$resp" =~ ^[sS]$ || -z "$resp" ]]
    echo ""
}

clear


echo -e "\033[7;33m----------------------------------------------GUNICORN---------------------------------------------\033[0m"
if [[ "$OMIT_GUNICORN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Iniciar Gunicorn, honeypot y livereload"); then
    echo -e "\033[7;30m🚀 Iniciando Gunicorn, honeypot y livereload simultáneamente...\033[0m"
    # clear
    cd "$PROJECT_ROOT"
    source "$VENV_PATH/bin/activate"
    python manage.py collectstatic --noinput
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    # Función para limpiar y salir
    cleanup() {
        echo -e "\n\033[1;33mDeteniendo todos los servicios...\033[0m"
        # Matar todos los procesos en segundo plano
        pids=$(jobs -p)
        if [ -n "$pids" ]; then
            kill $pids 2>/dev/null
        fi
        # Liberar puertos
        for port in 8001 5000 35729; do
            if lsof -i :$port > /dev/null; then
                echo "Liberando puerto $port..."
                kill $(lsof -t -i :$port) 2>/dev/null || true
            fi
        done
        echo -e "\033[1;32mTodos los servicios detenidos y puertos liberados.\033[0m"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
        echo ""
        exit 0
    }
    # Configurar trap para Ctrl+C
    trap cleanup SIGINT
    # Liberar puertos si es necesario
    for port in 8001 5000 35729; do
        if lsof -i :$port > /dev/null; then
            echo "Liberando puerto $port..."
            echo -e "\033[7;35m---///---///---///---///---///---///---///---///---\033[0m"
            echo ""
            kill $(lsof -t -i :$port) 2>/dev/null || true
        fi
    done
    # Iniciar servicios
    nohup gunicorn config.wsgi:application \
        --workers 3 \
        --bind 0.0.0.0:8001 \
        --keep-alive 2 \
        > gunicorn.log 2>&1 < /dev/null &
    nohup python honeypot.py \
        > honeypot.log 2>&1 < /dev/null &

    nohup livereload --host 0.0.0.0 --port 35729 static/ -t templates/ \
        > livereload.log 2>&1 < /dev/null &
    sleep 1

    firefox --new-tab  http://localhost:5000 --new-tab http://0.0.0.0:8000
    # firefox --new-tab http://0.0.0.0:8000 --new-tab http://localhost:5000 --new-tab https://apibank2-d42d7ed0d036.herokuapp.com/
    # firefox --new-tab http://0.0.0.0:8000 --new-tab https://apibank2-d42d7ed0d036.herokuapp.com &
    # gunicorn --certfile=cert.pem --keyfile=privkey.pem --bind 0.0.0.0:8443 config.wsgi:application

    # firefox --new-tab http://0.0.0.0:8000 &
    # firefox --new-window --width=400 --height=400 http://localhost:5000 &

    echo -e "\033[7;30m🚧 Gunicorn, honeypot y livereload están activos. Presiona Ctrl+C para detenerlos.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    # Esperar indefinidamente hasta que se presione Ctrl+C
    while true; do
        sleep 1
    done
    clear
fi
clear
echo ""
echo -e "\033[1;30m\n🏁 ¡Todo completado con éxito!\033[0m"