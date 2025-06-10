#!/usr/bin/env bash
set -euo pipefail

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


PROMPT_MODE=true
OMIT_SYNC_REMOTE_DB=false
OMIT_HEROKU=false
OMIT_GUNICORN=false
OMIT_CLEAN=false
OMIT_JSON_LOCAL=false
# OMIT_JSON_WEB=false
OMIT_SYNC_LOCAL=false
OMIT_ZIP_SQL=false
OMIT_MAC=false
OMIT_LOAD_LOCAL=false
OMIT_LOAD_WEB=false
OMIT_USER=false

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
    # echo "  -W, --omit-web              Omitir crear de JSON web"
    echo "  -S, --omit-sync             Omitir sincronización de archivos locales"
    echo "  -Z, --omit-zip              Omitir compresión de archivos"
    echo "  -M, --omit-mac              Omitir ajustes específicos para macOS"
    echo "  -U, --omit-create-user      Omitir crear usuario"
    echo "  -l, --omit-load-local       Omitir subir JSON local"
    echo "  -w, --omit-web              Omitir abrir web Heroku"
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
        # -W|--omit-web) OMIT_JSON_WEB=true; shift ;;
        -S|--omit-sync) OMIT_SYNC_LOCAL=true; shift ;;
        -Z|--omit-zip) OMIT_ZIP_SQL=true; shift ;;
        -U|--omit-create-user) OMIT_USER=true; shift ;;
        -l|--omit-load-local) OMIT_LOAD_LOCAL=true; shift ;;
        -w|--omit-web) OMIT_LOAD_WEB=true; shift ;;
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




# 🧱 Bloques del Script Maestro para Logging y Diagnóstico
# 🔧 BLOQUE 1 — Inicialización, funciones y diagnóstico del entorno
#     Define variables globales.
#     Crea directorio y archivo de log.
#     Declara funciones: log_info, log_ok, log_error, check_status, ejecutar, diagnostico_entorno.
#     Ejecuta diagnóstico completo del sistema.
PROMPT_MODE=true
OMIT_SYNC_REMOTE_DB=false
OMIT_HEROKU=false
OMIT_GUNICORN=false
OMIT_CLEAN=false
OMIT_JSON_LOCAL=false
# OMIT_JSON_WEB=false
OMIT_SYNC_LOCAL=false
OMIT_ZIP_SQL=false
OMIT_MAC=false
OMIT_LOAD_LOCAL=false
OMIT_LOAD_WEB=false
OMIT_USER=false

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
BACKUP_DIR="$HOME/Documentos/GitHub/backup/"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
HEROKU_ROOT2="$HOME/Documentos/GitHub/api_bank"
VENV_PATH="$HOME/Documentos/Entorno/envAPP"
LOGS_DIR="$HOME/Documentos/GitHub/api_bank_h2/logs"
INTERFAZ="wlan0"

DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="0.0.0.0"
REMOTE_DB_URL="postgres://u5n97bps7si3fm:pb87bf621ec80bf56093481d256ae6678f268dc7170379e3f74538c315bd549e0@c7lolh640htr57.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/dd3ico8cqsq6ra"


# === Ruta del log ===

LOG_FILE_SCRIPT="$LOGS_DIR/full_deploy_$(date +%Y%m%d_%H%M%S).log"

# === Funciones de log ===
log_info()    { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE_SCRIPT"; }
log_ok()      { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE_SCRIPT"; }
log_error()   { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE_SCRIPT"; }

check_status() {
    local status=$?
    if [ $status -ne 0 ]; then
        log_error "Fallo al ejecutar: $1"
        exit $status
    else
        log_ok "Éxito: $1"
    fi
}

# === Ejecutar comando con log de stdout/stderr ===
ejecutar() {
    log_info "➡️ Ejecutando: $*"
    "$@" >> "$LOG_FILE_SCRIPT" 2>&1
    check_status "$*"
}

# === Diagnóstico del entorno ===
diagnostico_entorno() {
    {
        echo -e "\n🔍 Diagnóstico del sistema - $(date)"
        echo "🧠 RAM:" && free -h
        echo -e "\n💾 Disco:" && df -h /
        echo -e "\n🧮 CPU:" && top -bn1 | grep "Cpu(s)"
        echo -e "\n🌐 Red:" && ip a | grep inet
        echo -e "\n🔥 Procesos activos relevantes:"
        ps aux | grep -E 'python|postgres|gunicorn' | grep -v grep
        echo -e "\n✅ Fin diagnóstico\n"
    } | tee -a "$LOG_FILE_SCRIPT"
}

# === Lanzar diagnóstico inicial ===
diagnostico_entorno



# 🛠 BLOQUE 2 — Actualización del sistema operativo
#     Ejecuta:
#         sudo apt-get update
#         sudo apt-get full-upgrade -y
#         sudo apt-get autoremove -y
#         sudo apt-get clean
#     Toda salida se guarda en log.
echo -e "\033[7;33m----------------------------------------------SISTEMA----------------------------------------------\033[0m"
log_info "🛠️  BLOQUE: Actualización del sistema operativo"

if confirmar "Actualizar sistema"; then
    ejecutar sudo apt-get update
    ejecutar sudo apt-get full-upgrade -y
    ejecutar sudo apt-get autoremove -y
    ejecutar sudo apt-get clean
    log_ok "🔄 Sistema actualizado correctamente"
    echo -e "\033[7;30m🔄 Sistema actualizado.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "❎ Usuario omitió la actualización del sistema"
fi

# 💾 BLOQUE 3 — Respaldo JSON local con dumpdata
#     Usa manage.py dumpdata para guardar bdd_local.json
#     Se exporta DATABASE_URL
#     Se registra resultado y salida completa.
echo -e "\033[7;33m------------------------------------------RESPALDOS LOCAL------------------------------------------\033[0m"
log_info "💾 BLOQUE: Creación de respaldo JSON local"

if [[ "$OMIT_JSON_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear bdd_local"); then
    log_info "🗃️ Exportando datos desde PostgreSQL a bdd_local.json"
    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"

    cd "$PROJECT_ROOT" || { log_error "❌ No se encontró el proyecto en $PROJECT_ROOT"; exit 1; }

    ejecutar python3 manage.py dumpdata --indent 2 > bdd_local.json
    log_ok "✅ Respaldo JSON creado exitosamente en $(realpath bdd_local.json)"
    echo -e "\033[7;30m✅ ¡Respaldo JSON Local creado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "📁 Respaldo JSON local omitido por configuración"
fi




# 🐘 BLOQUE 4 — Configuración de entorno virtual y PostgreSQL
#     Crea entorno virtual con python3 -m venv
#     Activa entorno, instala requirements
#     Activa y arranca PostgreSQL con systemctl
#     Registra stdout/stderr de pip install, enable/start postgresql
echo -e "\033[7;33m----------------------------------------------POSTGRES---------------------------------------------\033[0m"
log_info "🐘 BLOQUE: Configuración del entorno virtual y PostgreSQL"

if confirmar "Configurar venv y PostgreSQL"; then
    log_info "🧪 Creando entorno virtual en $VENV_PATH"
    ejecutar python3 -m venv "$VENV_PATH"

    source "$VENV_PATH/bin/activate"

    ejecutar python3 -m pip install --upgrade pip

    log_info "📦 Instalando dependencias desde requirements.txt"
    ejecutar pip install -r "$PROJECT_ROOT/requirements.txt"

    log_info "🔄 Habilitando y arrancando el servicio PostgreSQL"
    ejecutar sudo systemctl enable postgresql
    ejecutar sudo systemctl start postgresql

    log_ok "🐍 Entorno virtual y PostgreSQL configurados correctamente"
    echo -e "\033[7;30m🐍 Entorno y PostgreSQL listos.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "❎ Configuración de entorno y PostgreSQL omitida por el usuario"
fi




# 🔁 BLOQUE 5 — Resetear base de datos y crear usuario
#     Crea usuario y base de datos si no existen
#     Ejecuta bloques psql <<EOF, logueados con tee -a
#     Borra base si ya existe y la vuelve a crear
echo -e "\033[7;33m----------------------------------------------RESETEO----------------------------------------------\033[0m"
log_info "🔁 BLOQUE: Reseteo de la base de datos y creación de usuario"

if confirmar "Resetear base de datos y crear usuario en PostgreSQL"; then
    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"

    log_info "🔍 Verificando y creando usuario PostgreSQL si no existe..."
    sudo -u postgres psql <<EOF | tee -a "$LOG_FILE_SCRIPT"
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;

ALTER USER ${DB_USER} WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
EOF

    log_info "🧨 Verificando si existe la base de datos ${DB_NAME} para eliminarla..."
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
        log_info "⚠️ La base ${DB_NAME} existe. Terminando conexiones y eliminándola..."
        ejecutar sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';"
        ejecutar sudo -u postgres psql -c "DROP DATABASE ${DB_NAME};"
    else
        log_info "✅ La base de datos ${DB_NAME} no existe. Listo para crear."
    fi

    log_info "🚀 Creando nueva base de datos ${DB_NAME} y asignando permisos"
    sudo -u postgres psql <<EOF | tee -a "$LOG_FILE_SCRIPT"
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CREATE ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

    log_ok "🗃️ Base de datos y usuario listos para usar"
    echo -e "\033[7;30mBase de datos y usuario recreados.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "❎ Usuario omitió el reseteo de base de datos"
fi




# ⚙️ BLOQUE 6 — Migraciones de Django
#     Borra __pycache__, *.pyc, migrations/*.py
#     Ejecuta:
#         makemigrations
#         migrate
#     Usa ejecutar y registra todo
echo -e "\033[7;33m--------------------------------------------MIGRACIONES--------------------------------------------\033[0m"
log_info "⚙️ BLOQUE: Limpieza, generación y aplicación de migraciones Django"

if confirmar "Ejecutar migraciones"; then
    cd "$PROJECT_ROOT" || { log_error "❌ No se encontró el proyecto en $PROJECT_ROOT"; exit 1; }
    source "$VENV_PATH/bin/activate"

    log_info "🧹 Eliminando cachés de Python y migraciones anteriores"
    find . -path "*/__pycache__" -type d -exec rm -rf {} + 2>> "$LOG_FILE_SCRIPT"
    find . -name "*.pyc" -delete 2>> "$LOG_FILE_SCRIPT"
    find . -path "*/migrations/*.py" -not -name "__init__.py" -delete 2>> "$LOG_FILE_SCRIPT"
    find . -path "*/migrations/*.pyc" -delete 2>> "$LOG_FILE_SCRIPT"
    log_ok "🧼 Cachés y migraciones antiguas eliminadas"

    log_info "🔄 Generando nuevas migraciones..."
    ejecutar python3 manage.py makemigrations

    log_info "⏳ Aplicando migraciones a la base de datos..."
    ejecutar python3 manage.py migrate

    log_ok "✅ Migraciones aplicadas correctamente"
    echo -e "\033[7;30m⏳ Migraciones a la base de datos completa.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "❎ Migraciones de Django omitidas por el usuario"
fi




# 👤 BLOQUE 7 — Creación de superusuario
#     Usa manage.py createsuperuser
#     Se ejecuta manualmente (sin output automático), pero se puede loguear con un aviso
echo -e "\033[7;33m----------------------------------------------USUARIO----------------------------------------------\033[0m"
log_info "👤 BLOQUE: Creación de superusuario Django"

if [[ "$OMIT_USER" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear Super Usuario"); then
    cd "$PROJECT_ROOT" || { log_error "❌ No se encontró el proyecto en $PROJECT_ROOT"; exit 1; }
    source "$VENV_PATH/bin/activate"

    log_info "🧑‍💻 Ejecutando createsuperuser (interactivo)..."
    echo "👉 Por favor, completa los datos en pantalla (nombre, email, contraseña)."
    python3 manage.py createsuperuser | tee -a "$LOG_FILE_SCRIPT"

    if [ $? -eq 0 ]; then
        log_ok "✅ Superusuario creado correctamente"
    else
        log_error "❌ Error al crear el superusuario"
    fi

    echo -e "\033[7;30m✅ ¡Usuario creado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "👤 Creación de superusuario omitida por configuración"
fi




# 📥 BLOQUE 8 — Carga de respaldo JSON local
#     manage.py loaddata bdd_local.json
#     Todo en log
echo -e "\033[7;33m--------------------------------------------CARGAR LOCAL-------------------------------------------\033[0m"
log_info "📥 BLOQUE: Carga de respaldo JSON local en la base de datos"

if [[ "$OMIT_LOAD_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir bdd_local"); then
    cd "$PROJECT_ROOT" || { log_error "❌ No se encontró el proyecto en $PROJECT_ROOT"; exit 1; }
    source "$VENV_PATH/bin/activate"

    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"
    log_info "📤 Cargando archivo JSON: $(realpath bdd_local.json)"

    ejecutar python3 manage.py loaddata bdd_local.json

    log_ok "✅ Datos restaurados correctamente desde bdd_local.json"
    echo -e "\033[7;30m✅ ¡Subido JSON Local!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "📂 Carga del respaldo JSON local omitida por configuración"
fi




# 🧬 BLOQUE 9 — Sincronización local (rsync)
#     Ejecuta rsync hacia HEROKU_ROOT y HEROKU_ROOT2
#     Excluye archivos no deseados
#     Actualiza DJANGO_ENV en base1.py
#     Toda salida de rsync y python se guarda
echo -e "\033[7;33m----------------------------------------SINCRONIZACION LOCAL----------------------------------------\033[0m"
log_info "🧬 BLOQUE: Sincronización local del proyecto vía rsync y actualización de DJANGO_ENV"

# Exclusiones
EXCLUDES=(
    "--exclude=.gitattributes"
    "--exclude=.git/"
    "--exclude=01_full.sh"
    "--exclude=02_full.sh"
    "--exclude=*.json"
    "--exclude=*.zip"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    "--exclude=*.pyc"
    "--exclude=*.pyo"
    "--exclude=honeypot.py"
    "--exclude=temp/"
    "--exclude=*local.py"
    "--exclude=*.log"
)

# Función para actualizar DJANGO_ENV
actualizar_django_env() {
    local destino="$1"
    log_info "🧾 Ajustando DJANGO_ENV en base1.py en $destino"
    python3 <<EOF | tee -a "$LOG_FILE_SCRIPT"
import os
settings_path = os.path.join("$destino", "config", "settings", "base1.py")
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
        print("⚠️ No se encontró DJANGO_ENV='local' para actualizar.")
else:
    print("⚠️ No se encontró base1.py en el destino.")
EOF
}

if [[ "$OMIT_SYNC_LOCAL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Sincronizas archivos locales"); then
    for destino in "$HEROKU_ROOT" "$HEROKU_ROOT2"; do
        log_info "📂 Sincronizando archivos hacia: $destino"
        ejecutar rsync -av "${EXCLUDES[@]}" "$PROJECT_ROOT/" "$destino/"

        log_info "🧬 Sincronización completada. Ajustando entorno en $destino"
        cd "$destino" || { log_error "❌ Error accediendo a $destino"; exit 1; }
        actualizar_django_env "$destino"
        cd "$PROJECT_ROOT"
        echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    done
else
    log_info "🛑 Sincronización local omitida por configuración"
fi




# 🚀 BLOQUE 10 — Subida a GitHub y Heroku
#     git add, git commit, git push
#     git push heroku
#     heroku auth:token
#     Todo redirigido a log con ejecutar o tee
echo -e "\033[7;33m-------------------------------------------SUBIR A HEROKU------------------------------------------\033[0m"
log_info "🚀 BLOQUE: Deploy a GitHub + Heroku"

if [[ "$OMIT_HEROKU" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir el proyecto a la web"); then
    cd "$HEROKU_ROOT" || { log_error "❌ Error al acceder a $HEROKU_ROOT"; exit 1; }

    log_info "📂 Preparando commit en GitHub (rama api-bank)"
    ejecutar git add --all

    echo -e "\033[7;30m📝 Por favor, ingresa el comentario del commit:\033[0m"
    read -p "✏️  Comentario: " COMENTARIO_COMMIT

    if [[ -z "$COMENTARIO_COMMIT" ]]; then
        log_error "❌ No se puede continuar sin comentario de commit"
        exit 1
    fi

    log_info "✅ Commit con mensaje: $COMENTARIO_COMMIT"
    git commit -m "$COMENTARIO_COMMIT" 2>&1 | tee -a "$LOG_FILE_SCRIPT"
    check_status "git commit"

    log_info "⬆️ Subiendo a GitHub..."
    git push origin api-bank 2>&1 | tee -a "$LOG_FILE_SCRIPT"
    check_status "git push origin api-bank"

    sleep 5

    export HEROKU_API_KEY="HRKU-6803f1ea-fd1f-4210-a5cd-95ca7902ccf6"
    log_info "🔐 Autenticando con Heroku..."
    echo "$HEROKU_API_KEY" | heroku auth:token > /dev/null 2>&1
    check_status "heroku auth"

    log_info "☁️ Haciendo deploy a Heroku..."
    git push heroku api-bank:main 2>&1 | tee -a "$LOG_FILE_SCRIPT"
    check_status "git push heroku"

    cd "$PROJECT_ROOT"
    log_ok "✅ Proyecto desplegado con éxito en Heroku y GitHub"

    echo -e "\033[7;30m✅ ¡Deploy completado!\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "🚫 Deploy a GitHub y Heroku omitido por configuración"
fi




# 🌐 BLOQUE 11 — Sincronización de base de datos con la nube
#     Usa pg_dump, pv, psql
#     Borra y resetea schema remoto
#     Crea archivo .sql local
#     Todo el flujo se registra con log_info + ejecutar
echo -e "\033[7;33m---------------------------------------SINCRONIZACION BDD WEB--------------------------------------\033[0m"
log_info "🌐 BLOQUE: Sincronización de base de datos local a nube remota PostgreSQL"

if [[ "$OMIT_SYNC_REMOTE_DB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Subir las bases de datos a la web"); then
    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="${BACKUP_DIR}backup_${DATE}.sql"
    export PGPASSFILE="$HOME/.pgpass"
    export PGUSER="$DB_USER"
    export PGHOST="$DB_HOST"

    if ! command -v pv > /dev/null 2>&1; then
        log_error "❌ La herramienta 'pv' no está instalada. Instálala con: sudo apt install pv"
        exit 1
    fi

    log_info "🧹 Reseteando base de datos remota (DROP SCHEMA)..."
    echo "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" | psql "$REMOTE_DB_URL" 2>&1 | tee -a "$LOG_FILE_SCRIPT"
    check_status "DROP y CREATE SCHEMA remoto"

    log_info "📦 Generando backup local con pg_dump..."
    ejecutar pg_dump --no-owner --no-acl -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" > "$BACKUP_FILE"
    log_ok "📄 Backup SQL generado: $BACKUP_FILE"

    log_info "📤 Subiendo backup a la base de datos remota con pv + psql..."
    pv "$BACKUP_FILE" | psql "$REMOTE_DB_URL" >> "$LOG_FILE_SCRIPT" 2>&1
    check_status "Importación a DB remota"

    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"
    log_ok "✅ Sincronización completada correctamente"
    echo -e "\033[7;30m✅ Sincronización completada con éxito: $BACKUP_FILE\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "🌐 Sincronización con base de datos remota omitida"
fi




# 📦 BLOQUE 12 — Creación de archivo ZIP de respaldo
#     Crea .zip con zip -r
#     Usa timestamp + contador
#     Puede incluir limpieza de backups antiguos por fecha
echo -e "\033[7;33m--------------------------------------------------ZIP----------------------------------------------\033[0m"
log_info "📦 BLOQUE: Creación de archivo ZIP comprimido del proyecto"

if [[ "$OMIT_ZIP_SQL" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Crear zip y sql"); then
    SOURCE="$PROJECT_ROOT/"
    DEST="$HEROKU_ROOT"
    BACKUP_DIR="$HOME/Documentos/GitHub/backup/"

    TODAY=$(date +%Y%m%d)
    COUNT=$(ls "$BACKUP_DIR" | grep "^${TODAY}__.*_backup_api_bank_h2[0-9]*\.zip$" | wc -l)
    SUFFIX=$((COUNT + 1))
    TIMESTAMP=$(date +%Y%m%d__%H-%M-%S)
    BACKUP_ZIP="${BACKUP_DIR}${TIMESTAMP}_backup_api_bank_h2${SUFFIX}.zip"

    mkdir -p "$DEST" "$BACKUP_DIR"

    log_info "📁 Comenzando compresión del proyecto en $BACKUP_ZIP"

    (
        cd "$(dirname "$SOURCE")" || { log_error "❌ No se pudo acceder a la carpeta fuente"; exit 1; }
        zip -r "$BACKUP_ZIP" "$(basename "$SOURCE")" \
            -x "*.git*" "*.zip" "*.sqlite3" "*.db" "*.pyc" "*.pyo" \
            "*__pycache__*" "*temp/*" "*.log" "*local.py" 2>&1
    ) | tee -a "$LOG_FILE_SCRIPT"
    check_status "zip del proyecto"

    log_ok "✅ ZIP creado exitosamente en: $BACKUP_ZIP"
    echo -e "\033[7;30m✅ Respaldo ZIP creado en: $BACKUP_ZIP\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "📦 Creación de archivo ZIP omitida por configuración"
fi




# 🧹 BLOQUE 13 — Limpieza de archivos .zip y .sql viejos
#     Mantiene el primero y último por día, +10 más recientes de hoy
#     Elimina lo demás
#     Registra archivos borrados
echo -e "\033[7;33m-----------------------------------------BORRANDO ZIP Y SQL----------------------------------------\033[0m"
log_info "🧹 BLOQUE: Limpieza de respaldos antiguos (.zip y .sql)"

if [[ "$OMIT_CLEAN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Limpiar respaldos antiguos"); then
    cd "$BACKUP_DIR" || { log_error "❌ No se pudo acceder al directorio $BACKUP_DIR"; exit 1; }

    mapfile -t files < <(ls -1tr *.zip *.sql 2>/dev/null)
    declare -A first last all keep

    for f in "${files[@]}"; do
        d=${f:10:8}  # Extrae fecha del nombre
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
            log_info "🗑️ Eliminando respaldo obsoleto: $f"
            rm -f "$f" && log_ok "✅ Archivo eliminado: $f"
            echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a "$LOG_FILE_SCRIPT"
        else
            log_info "📁 Conservando respaldo: $f"
        fi
    done

    cd - >/dev/null
else
    log_info "🧹 Limpieza de respaldos omitida por configuración"
fi




# 🎭 BLOQUE 14 — Cambio de MAC address (opcional)
#     Usa macchanger para interfaz como wlan0
#     Redirigido al log
echo -e "\033[7;33m---------------------------------------------CAMBIO MAC--------------------------------------------\033[0m"
log_info "🎭 BLOQUE: Cambio de dirección MAC en interfaz $INTERFAZ"

if [[ "$OMIT_MAC" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Cambiar MAC de la interfaz $INTERFAZ"); then
    if ! command -v macchanger > /dev/null 2>&1; then
        log_error "❌ El comando 'macchanger' no está instalado. Instálalo con: sudo apt install macchanger"
        exit 1
    fi

    log_info "🛑 Bajando interfaz $INTERFAZ"
    ejecutar sudo ip link set "$INTERFAZ" down

    MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
    MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')

    log_info "🔄 MAC anterior: $MAC_ANTERIOR"
    log_info "✨ Nueva MAC asignada: $MAC_NUEVA"

    log_info "🔼 Subiendo interfaz $INTERFAZ"
    ejecutar sudo ip link set "$INTERFAZ" up

    log_ok "✅ Dirección MAC cambiada correctamente en $INTERFAZ"
    echo -e "\033[7;30m🔍 MAC anterior: $MAC_ANTERIOR\033[0m"
    echo -e "\033[7;30m🎉 MAC asignada: $MAC_NUEVA\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo "" | tee -a "$LOG_FILE_SCRIPT"
else
    log_info "🎭 Cambio de MAC omitido por configuración"
fi




# 🔒 BLOQUE 15 — Arranque de Gunicorn, honeypot y livereload
#     Ejecuta 3 procesos con nohup
#     Usa firefox para abrir URLs
#     Registra PID de procesos y abre puerto
#     Salida a gunicorn.log, honeypot.log, livereload.log y LOG_FILE_SCRIPT
echo -e "\033[7;33m----------------------------------------------GUNICORN---------------------------------------------\033[0m"
log_info "🔒 BLOQUE: Inicio de Gunicorn, Honeypot y Livereload"

PUERTOS=(8001 5000 35729)
URL_LOCAL="http://0.0.0.0:5000"
URL_GUNICORN="http://0.0.0.0:8000"
LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

liberar_puertos() {
    for port in "${PUERTOS[@]}"; do
        if lsof -i :"$port" > /dev/null 2>&1; then
            log_info "🔌 Liberando puerto $port"
            kill $(lsof -t -i :"$port") >> "$LOG_FILE_SCRIPT" 2>&1 || true
            log_ok "✅ Puerto $port liberado"
        fi
    done
}

limpiar_y_salir() {
    log_info "🧹 Deteniendo servicios..."
    pids=$(jobs -p)
    [ -n "$pids" ] && kill $pids 2>/dev/null
    [ -n "${FIREFOX_PID:-}" ] && kill "$FIREFOX_PID" 2>/dev/null || true
    liberar_puertos
    log_ok "✅ Todos los procesos detenidos correctamente"
    echo -e "$LOGO_SEP\n"
    exit 0
}

iniciar_entorno() {
    cd "$PROJECT_ROOT" || { log_error "❌ No se pudo acceder al proyecto"; exit 1; }
    source "$VENV_PATH/bin/activate"
    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"
    ejecutar python manage.py collectstatic --noinput
}

if [[ "$OMIT_GUNICORN" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Iniciar Gunicorn, honeypot y livereload"); then
    trap limpiar_y_salir SIGINT
    liberar_puertos
    iniciar_entorno

    log_info "🚀 Lanzando Gunicorn..."
    nohup gunicorn config.wsgi:application --workers 3 --bind 0.0.0.0:8001 --keep-alive 2 > gunicorn.log 2>&1 &
    log_ok "✅ Gunicorn iniciado en :8001 (PID $!)"

    log_info "🕵️‍♂️ Lanzando honeypot SSH..."
    nohup python honeypot.py > honeypot.log 2>&1 &
    log_ok "✅ Honeypot iniciado (PID $!)"

    log_info "👨‍🔬 Lanzando livereload..."
    nohup livereload --host 0.0.0.0 --port 35729 static/ -t templates/ > livereload.log 2>&1 &
    log_ok "✅ Livereload iniciado en :35729 (PID $!)"

    sleep 3
    firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN" &
    FIREFOX_PID=$!

    log_ok "🌐 Navegador lanzado en $URL_LOCAL y $URL_GUNICORN"
    echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
    echo -e "$LOGO_SEP\n"
    while true; do sleep 3; done
else
    log_info "🔒 Arranque de servicios omitido por configuración"
fi




# 🌍 BLOQUE 16 — Abrir web de Heroku
#     Lanza firefox con URL_HEROKU
#     Se registra evento y PID
echo -e "\033[7;33m---------------------------------------------CARGAR WEB--------------------------------------------\033[0m"
log_info "🌍 BLOQUE: Apertura de web Heroku en navegador"

URL_HEROKU="https://apibank2-54644cdf263f.herokuapp.com/"

if [[ "$OMIT_LOAD_WEB" == false ]] && ([[ "$PROMPT_MODE" == false ]] || confirmar "Abrir web Heroku"); then
    trap limpiar_y_salir SIGINT
    liberar_puertos
    iniciar_entorno

    log_info "🌐 Abriendo navegador con URL Heroku: $URL_HEROKU"
    firefox --new-window "$URL_HEROKU" &
    FIREFOX_PID=$!
    log_ok "🧭 Navegador lanzado (PID $FIREFOX_PID)"

    echo -e "\033[7;30m🚧 Web Heroku activa. Ctrl+C para cerrar.\033[0m"
    echo -e "$LOGO_SEP\n"

    # === Notificación de escritorio ===
    notify-send "API_BANK_H2" "✅ Proyecto desplegado correctamente

🌍 Local:
$URL_LOCAL

🚀 Producción:
$URL_HEROKU

📦 Backup SQL: $BACKUP_FILE
🔖 Commit: $COMENTARIO_COMMIT
🗜️ ZIP: $BACKUP_ZIP

🧾 Log: $LOG_FILE_SCRIPT" || log_info "📭 Notificación omitida: notify-send no disponible"

    while true; do sleep 3; done
else
    log_info "🌍 Apertura de navegador Heroku omitida por configuración"
fi




# 🔔 BLOQUE 17 — Notificación final con notify-send
#     Muestra éxito del deploy
#     Incluye URLs y resumen
#     El mensaje final también se guarda en log
echo -e "\033[7;33m------------------------------------------NOTIFICACIÓN FINAL----------------------------------------\033[0m"
log_info "🔔 BLOQUE: Notificación final del proceso de despliegue"

notify-send "API_BANK_H2" "✅ Proyecto iniciado correctamente

🌐 Accesos:
- Local: $URL_LOCAL
- Producción: $URL_HEROKU

📦 Respaldo SQL: $BACKUP_FILE
🗜️ ZIP: $BACKUP_ZIP
🔖 Commit: $COMENTARIO_COMMIT

🧾 Log completo:
$LOG_FILE_SCRIPT" || log_info "📭 notify-send no disponible en este entorno"

log_ok "🏁 Script completado con éxito. Log guardado en: $LOG_FILE_SCRIPT"
echo -e "\033[1;32m🏁 ¡Todo completado con éxito!\033[0m"
echo -e "\033[1;34m🧾 Log disponible en: $LOG_FILE_SCRIPT\033[0m"
