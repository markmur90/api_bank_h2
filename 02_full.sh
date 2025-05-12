#!/usr/bin/env bash
set -euo pipefail

PROMPT_MODE=true
OMIT_SYNC_REMOTE_DB=false
OMIT_HEROKU=false
OMIT_GUNICORN=false
OMIT_CLEAN=false
OMIT_JSON_LOCAL=false
OMIT_JSON_WEB=false
OMIT_SYNC_LOCAL=false
OMIT_ZIP_SQL=false
OMIT_MAC=false
OMIT_LOAD_LOCAL=false
OMIT_LOAD_WEB=false
OMIT_USER=false

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
BACKUP_DIR="$HOME/Documentos/GitHub/backup/"
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
    echo "  -B, --omit-bdd              Omitir sincronización de la base de datos remota"
    echo "  -H, --omit-heroku           Omitir despliegue en Heroku"
    echo "  -G, --omit-gunicorn         Omitir arranque del servidor Gunicorn"
    echo "  -L, --omit-local            Omitir crear de JSON local"
    echo "  -W, --omit-web              Omitir crear de JSON web"
    echo "  -S, --omit-sync             Omitir sincronización de archivos locales"
    echo "  -Z, --omit-zip              Omitir compresión de archivos"
    echo "  -M, --omit-mac              Omitir ajustes específicos para macOS"
    echo "  -U, --omit-create-user      Omitir crear usuario"
    echo "  -l, --omit-load-local       Omitir subir JSON local"
    echo "  -w, --omit-load-web         Omitir subir JSON web"
    echo "  -C, --omit-clean            Omitir limpieza de archivos temporales"
    echo "  -h, --help                  Mostrar esta ayuda y salir"
    echo
}
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all) PROMPT_MODE=false; shift ;;
        -s|--step) PROMPT_MODE=true; shift ;;
        -B|--omit-bdd) OMIT_SYNC_REMOTE_DB=true; shift ;;
        -H|--omit-heroku) OMIT_HEROKU=true; shift ;;
        -G|--omit-gunicorn) OMIT_GUNICORN=true; shift ;;
        -L|--omit-local) OMIT_JSON_LOCAL=true; shift ;;
        -W|--omit-web) OMIT_JSON_WEB=true; shift ;;
        -S|--omit-sync) OMIT_SYNC_LOCAL=true; shift ;;
        -Z|--omit-zip) OMIT_ZIP_SQL=true; shift ;;
        -U|--omit-create-user) OMIT_USER=true; shift ;;
        -l|--omit-load-local) OMIT_LOAD_LOCAL=true; shift ;;
        -w|--omit-load-web) OMIT_LOAD_WEB=true; shift ;;
        -M|--omit-mac) OMIT_MAC=true; shift ;;
        -C|--omit-clean) OMIT_CLEAN=true; shift ;;
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


# 1. Puertos
if confirmar "Detener puertos abiertos"; then
    for PUERTO in 2222 8000 5000 8001 35729; do
        if lsof -i tcp:"$PUERTO" &>/dev/null; then
            if confirmar "Cerrar procesos en puerto $PUERTO"; then
                sudo fuser -k "${PUERTO}"/tcp || true
                echo -e "\033[7;30m✅ Puerto $PUERTO liberado.\033[0m"
                echo -e "\033[7;30m----------///--------------------///----------\033[0m"
                echo ""
            fi
        fi
    done
fi
echo -e "\033[7;33m-------------PUERTOS--------------\033[0m"
echo ""
echo ""
sleep 1


# 2. Docker
if confirmar "Detener contenedores Docker"; then
    PIDS=$(docker ps -q)
    if [ -n "$PIDS" ]; then
        docker stop $PIDS
        echo -e "\033[7;30m🐳 Contenedores detenidos.\033[0m"
        echo -e "\033[7;30m----------///--------------------///----------\033[0m"
        echo ""
    else
        echo -e "\033[7;30m🐳 No hay contenedores.\033[0m"
        echo -e "\033[7;30m----------///--------------------///----------\033[0m"
        echo ""
    fi
fi
echo -e "\033[7;33m-----------CONTENEDORES------------\033[0m"
echo ""
echo ""



# 3. Actualizar sistema
if confirmar "Actualizar sistema"; then
    sudo apt update && sudo apt upgrade -y
    echo -e "\033[7;30m🔄 Sistema actualizado.\033[0m"
fi
echo -e "\033[7;33m-------------SISTEMA--------------\033[0m"
echo ""
echo ""

if [[ "$OMIT_JSON_WEB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear bdd_web"); then
    echo -e "\033[7;30m🚀 Creando respaldo de datos de web...\033[0m"
    export DATABASE_URL="postgres://ue2erdhkle4v0h:pa1773a2b68d739e66a794acd529d1b60c016733f35be6884a9f541365d5922cf@ec2-63-33-30-239.eu-west-1.compute.amazonaws.com:5432/d9vb99r9t1m7kt"
    python3 manage.py dumpdata --indent 2 > bdd_web.json
    echo -e "\033[7;30m✅ ¡Respaldo JSON Web creado!\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m----------RESPALDOS WEB-----------\033[0m"
echo ""
echo ""
sleep 1


if [[ "$OMIT_JSON_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear bdd_local"); then
    echo -e "\033[7;30m🚀 Creando respaldo de datos de local...\033[0m"
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    python3 manage.py dumpdata --indent 2 > bdd_local.json
    echo -e "\033[7;30m✅ ¡Respaldo JSON Local creado!\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m---------RESPALDOS LOCAL----------\033[0m"
echo ""
echo ""
sleep 1





# 4. Entorno Python y PostgreSQL
if confirmar "Configurar venv y PostgreSQL"; then
    python3 -m venv "$VENV_PATH"
    source "$VENV_PATH/bin/activate"
    pip install --upgrade pip
    echo "📦 Instalando dependencias..."
    echo ""
    pip install -r "$PROJECT_ROOT/requirements.txt"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    echo -e "\033[7;30m🐍 Entorno y PostgreSQL listos.\033[0m"
    echo ""
fi
echo -e "\033[7;33m-------------POSTGRES--------------\033[0m"
echo ""
echo ""


# 5. Firewall
if confirmar "Configurar UFW"; then
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 2222/tcp
    sudo ufw allow 8000/tcp
    sudo ufw allow 8443/tcp
    sudo ufw allow 5000/tcp
    sudo ufw allow 35729/tcp
    sudo ufw allow from 127.0.0.1 to any port 8001 proto tcp comment "Gunicorn local backend"
    sudo ufw deny 22/tcp comment "Bloquear SSH real en 22"
    sudo ufw enable
    echo -e "\033[7;30m🔐 Reglas de UFW aplicadas con éxito.\033[0m"
    echo ""
fi
echo -e "\033[7;33m---------------UFW----------------\033[0m"
echo ""
echo ""









# 7. DB: reset y usuario
if confirmar "Resetear base de datos y crear usuario en PostgreSQL"; then
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    sudo -u postgres psql <<-EOF
DO \$\$
BEGIN
    -- Verificar si el usuario ya existe
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;

-- Asignar permisos al usuario
ALTER USER ${DB_USER} WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
EOF

# Verificar si la base de datos existe y eliminarla si es necesario
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1
if [ $? -eq 0 ]; then
    echo "La base de datos ${DB_NAME} existe. Eliminándola..."
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';"
    sudo -u postgres psql -c "DROP DATABASE ${DB_NAME};"
fi

# Crear la base de datos y asignar permisos
sudo -u postgres psql <<-EOF
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CREATE ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF
    echo -e "\033[7;30mBase de datos y usuario recreados.\033[0m"
    echo ""
fi
echo -e "\033[7;33m-------------RESETEO--------------\033[0m"
echo ""
echo ""


# 7. Migraciones
if confirmar "Ejecutar migraciones"; then
    cd "$PROJECT_ROOT"
    source "$VENV_PATH/bin/activate"
    echo "🧹 Eliminando cachés de Python y migraciones anteriores..."
    find . -path "*/__pycache__" -type d -exec rm -rf {} +
    find . -name "*.pyc" -delete
    find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
    find . -path "*/migrations/*.pyc" -delete
    echo "🔄 Generando migraciones de Django..."
    python manage.py makemigrations
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    echo "⏳ Aplicando migraciones de la base de datos..."
    python manage.py migrate
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m-----------MIGRACIONES------------\033[0m"
echo ""
echo ""
sleep 1


if [[ "$OMIT_USER" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear Super Usuario"); then
    echo -e "\033[7;30m🚀 Creando usuario...\033[0m"
    python3 manage.py createsuperuser
    echo -e "\033[7;30m✅ ¡Usuario creado!\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m-------------USUARIO--------------\033[0m"
echo ""
echo ""
sleep 1


if [[ "$OMIT_LOAD_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir bdd_local"); then
    echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m"
    python3 manage.py loaddata bdd_local.json
    echo -e "\033[7;30m✅ ¡Subido JSON Local!\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m-----------CARGAR LOCAL------------\033[0m"
echo ""
echo ""
sleep 1

if [[ "$OMIT_LOAD_WEB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir bdd_web"); then
    echo -e "\033[7;30m🚀 Subiendo respaldo de datos de web...\033[0m"
    python3 manage.py loaddata bdd_web.json
    echo -e "\033[7;30m✅ ¡Subido JSON Web!\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m------------CARGAR WEB-------------\033[0m"
echo ""
echo ""
sleep 1








# 9. Generar claves
if confirmar "Generar o cambiar PEM JWKS"; then
    python3 manage.py genkey
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m-------------PEM JWKS--------------\033[0m"
echo ""
echo ""
sleep 1




# 10. Sincronizar a Heroku

EXCLUDES=(
    "--exclude=.gitattributes"
    "--exclude=.git/"
    "--exclude=01_full.sh"
    "--exclude=api_bank_heroku.txt"
    "--exclude=auto_commit_sync.sh"
    "--exclude=bdd_local.json"
    "--exclude=bdd_web.json"
    "--exclude=colores.sh"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    "--exclude=*.zip"
    "--exclude=gunicorn.log"
    "--exclude=honeypot.log"
    "--exclude=honeypot.py"
    "--exclude=honeypot_logs.csv"
    "--exclude=livereload.log"
    "--exclude=*local.py"
    "--exclude=temp/"
)

if [[ "$OMIT_SYNC_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Sincronizas archivos locales"); then
    echo "🔄 Sincronizando archivos al destino..."
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    rsync -av "${EXCLUDES[@]}" "$PROJECT_ROOT/" "$HEROKU_ROOT/"
    echo -e "\033[7;30m📂 Cambios enviados a api_bank_heroku.\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    echo "🌍 Actualizando DJANGO_ENV en base1.py..."
    cd "$HEROKU_ROOT"
    python3 <<EOF
import os
from pathlib import Path
settings_path="$HEROKU_ROOT/config/settings/base1.py"

if os.path.exists(settings_path):
    with open(settings_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    updated = False
    new_lines = []
    for line in lines:
        if "DJANGO_ENV = os.getenv(" in line and "'local'" in line:
            new_lines.append(line.replace("'local'", "'production'"))
            updated = True
        else:
            new_lines.append(line)

    if updated:
        with open(settings_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print("✅ DJANGO_ENV actualizado a 'production' en base1.py.")
    else:
        print("⚠️ No se encontró 'DJANGO_ENV' con valor 'local' para actualizar.")
else:
    print("⚠️ No se encontró base1.py para actualizar DJANGO_ENV.")
EOF

    sleep 1
    cd "$PROJECT_ROOT"
    echo ""
fi

echo -e "\033[7;33m-------SINCRONIZACION LOCAL--------\033[0m"
echo ""
echo ""
sleep 1





# 11. Respaldo ZIP y SQL
if [[ "$OMIT_ZIP_SQL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear zip y sql"); then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ZIP_PATH="$BACKUP_DIR/respaldo_${TIMESTAMP}.zip"
    zip -r "$ZIP_PATH" "$PROJECT_ROOT" \
        -x "$PROJECT_ROOT/venvAPI/*" "$PROJECT_ROOT/backup/*" "$PROJECT_ROOT/*.zip"
    echo -e "\033[7;30m📦 ZIP creado: $ZIP_PATH.\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m-------------ZIP SQL--------------\033[0m"
echo ""
echo ""
sleep 1



# 12. Sincronizar BDD
if [[ "$OMIT_SYNC_REMOTE_DB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir las bases de datos a la web"); then
    echo -e "\033[7;30m🚀 Subiendo las bses de datos...\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""

    REMOTE_DB_URL="postgres://ue2erdhkle4v0h:pa1773a2b68d739e66a794acd529d1b60c016733f35be6884a9f541365d5922cf@ec2-63-33-30-239.eu-west-1.compute.amazonaws.com:5432/d9vb99r9t1m7kt"
    # **🕒 Marca de tiempo para el backup**
    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="$HOME/Documentos/GitHub/backup/"
    # Crear el directorio de backup si no existe
    BACKUP_FILE="${BACKUP_DIR}backup_${DATE}.sql"
    if ! command -v pv > /dev/null 2>&1; then
        echo "⚠️ La herramienta 'pv' no está instalada. Instálala con: sudo apt install pv"
        echo -e "\033[7;30m----------///--------------------///----------\033[0m"
        exit 1
    fi
    echo "🧹 Reseteando base de datos remota..."
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    psql "$REMOTE_DB_URL" -q -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" || { echo "❌ Error al resetear la DB remota. Abortando."; exit 1; }
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    echo "📦 Generando backup local..."
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    pg_dump --no-owner --no-acl -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" > "$BACKUP_FILE" || { echo "❌ Error haciendo el backup local. Abortando."; exit 1; }
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    echo "🌐 Importando backup en la base de datos remota..."
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    pv "$BACKUP_FILE" | psql "$REMOTE_DB_URL" -q > /dev/null || { echo "❌ Error al importar el backup en la base de datos remota."; exit 1; }
    echo "✅ Sincronización completada con éxito: $BACKUP_FILE"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m------SINCRONIZACION BDD WEB-------\033[0m"
echo ""
echo ""
sleep 1



# 13. Retención de backups
if [[ "$OMIT_CLEAN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Limpiar respaldos antiguos"); then
    echo "🚀 Limpiando..."
    echo ""
    cd "$BACKUP_DIR"
    mapfile -t files < <(ls -1tr *.zip *.sql 2>/dev/null)
    declare -A first last all keep
    for f in "${files[@]}"; do
        d=${f:10:8}
        all["$d"]+="$f;"
        [[ -z "${first[$d]:-}" ]] && first[$d]=$f
        last[$d]=$f
    done
    today=$(date +%Y%m%d)
    for d in "${!first[@]}"; do keep["${first[$d]}"]=1; done
    for d in "${!last[@]}";  do keep["${last[$d]}"]=1;  done
    today_files=(); for f in "${files[@]}"; do [[ "${f:10:8}" == "$today" ]] && today_files+=("$f"); done
    n=${#today_files[@]}; s=$(( n>10 ? n-10 : 0 ))
    for ((i=s;i<n;i++)); do keep["${today_files[i]}"]=1; done
    for f in "${files[@]}"; do
        if [[ -z "${keep[$f]:-}" ]]; then 
            rm -f "$f" && echo -e "\033[7;30m🗑️ Eliminado $f.\033[0m"
            echo -e "\033[7;30m----------///--------------------///----------\033[0m"
            echo ""
        fi
    done
    cd - >/dev/null
fi
echo -e "\033[7;33m--------BORRANDO ZIP Y SQL---------\033[0m"
echo ""
echo ""
sleep 1



# 14. Subir datos a Heroku
if [[ "$OMIT_HEROKU" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir el proyecto a la web"); then
    echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 1; }
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    # Git commit y push (automático)
    git add --all
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    git commit -m "fix: Actualizar ajustes"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    git push origin api-bank || { echo -e "\033[7;30m❌ Error al subir a GitHub\033[0m"; exit 1; }
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    sleep 10
    heroku login || { echo -e "\033[7;30m❌ Error en login de Heroku\033[0m"; exit 1; }
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    sleep 10
    git push heroku api-bank:main || { echo -e "\033[7;30m❌ Error en deploy\033[0m"; exit 1; }
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    sleep 10
    cd "$PROJECT_ROOT"
    echo -e "\033[7;30m✅ ¡Deploy completado!\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m----------SUBIR A HEROKU-----------\033[0m"
echo ""
echo ""
sleep 1



# 15. Cambiar MAC
if [[ "$OMIT_MAC" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Cambiar MAC de la interfaz $INTERFAZ"); then
    sudo ip link set "$INTERFAZ" down
    MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
    MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
    sudo ip link set "$INTERFAZ" up
    echo -e "\033[7;30m🔍 MAC anterior: $MAC_ANTERIOR\033[0m"
    echo -e "\033[7;30m🎉 MAC asignada: $MAC_NUEVA\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
fi
echo -e "\033[7;33m------------CAMBIO MAC-------------\033[0m"
echo ""
echo ""
sleep 1





# 16. Despliegue
if [[ "$OMIT_GUNICORN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Iniciar Gunicorn, honeypot y livereload"); then
    echo "🚀 Iniciar Gunicorn, honeypot y livereload simultáneamente..."
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    # clear
    cd "$PROJECT_ROOT"
    source "$VENV_PATH/bin/activate"
    python manage.py collectstatic --noinput
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    # Función para limpiar y salir
    cleanup() {
        echo -e "\n\033[1;33mDeteniendo todos los servicios...\033[0m"
        echo -e "\033[7;30m----------///--------------------///----------\033[0m"
        echo ""
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
        echo -e "\033[7;30m----------///--------------------///----------\033[0m"
        echo ""
        exit 0
    }
    # Configurar trap para Ctrl+C
    trap cleanup SIGINT
    # Liberar puertos si es necesario
    for port in 8001 5000 35729; do
        if lsof -i :$port > /dev/null; then
            echo "Liberando puerto $port..."
            echo -e "\033[7;30m----------///--------------------///----------\033[0m"
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

    firefox --new-tab http://0.0.0.0:8000 --new-tab http://localhost:5000 --new-tab https://localhost:8443

    gunicorn --certfile=cert.pem --keyfile=privkey.pem --bind 0.0.0.0:8443 config.wsgi:application

    echo -e "\033[7;30m🚧 Gunicorn, honeypot y livereload están activos. Presiona Ctrl+C para detenerlos.\033[0m"
    echo -e "\033[7;30m----------///--------------------///----------\033[0m"
    echo ""
    # Esperar indefinidamente hasta que se presione Ctrl+C
    while true; do
        sleep 1
    done
fi
echo -e "\033[7;33m-------------GUNICORN--------------\033[0m"
echo ""
echo ""
sleep 1



# 17. Despliegue
if [ "$OMIT_HEROKU" != "1" ]; then
    echo "Lanzando navegador hacia Heroku..."
    if which xdg-open > /dev/null 2>&1; then
        xdg-open "https://api-bank-heroku-72c443ab11d3.herokuapp.com/"
    elif which open > /dev/null 2>&1; then
        open "https://api-bank-heroku-72c443ab11d3.herokuapp.com/"
    else
        echo "No se pudo abrir el navegador automáticamente. Abre manualmente: https://api-bank-heroku-72c443ab11d3.herokuapp.com/"
    fi
fi

# clear
echo -e "\033[7;33m------------WEB HEROKU-------------\033[0m"
echo ""
echo ""


echo -e "\033[1;30m\n🏁 ¡Todo completado con éxito!\033[0m"