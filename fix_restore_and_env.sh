#!/usr/bin/env bash

echo "🔧 Script temporal para corregir restore_and_upload_force.sh"

# 1. Ejecutar solo la restauración de la BD (sin variables)
echo "📦 PASO 1: Restaurando base de datos..."
DB_USER="markmur88"
DB_PASSWORD="Ptf8454Jd55"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="mydatabase"
BACKUP_FILE="backup_local.sql"

# Exporta la contraseña para que los comandos no la pidan
export PGPASSWORD="$DB_PASSWORD"

echo "Cerrando todas las conexiones existentes a la base de datos '$DB_NAME'..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "postgres" -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"

echo "Eliminando la base de datos antigua '$DB_NAME' (si existe)..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "postgres" -c "DROP DATABASE IF EXISTS $DB_NAME;"

echo "Creando una base de datos limpia '$DB_NAME'..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "postgres" -c "CREATE DATABASE $DB_NAME;"

echo "Restaurando la base de datos..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" < "$BACKUP_FILE"

echo "✅ Restauración completada."

# 2. Ejecutar migraciones para crear tablas faltantes
echo "🔄 PASO 2: Ejecutando migraciones Django..."
source /home/markmur88/envAPP/bin/activate
python manage.py migrate --skip-checks

# 3. Procesar archivos .env con el script Python
echo "📝 PASO 3: Subiendo variables desde archivos .env..."
if [ -f ".env.local" ]; then
    echo "Procesando archivo: '.env.local' para el entorno: 'local'"
    python importar_env_a_db.py .env.local local
fi

if [ -f ".env.production" ]; then
    echo "Procesando archivo: '.env.production' para el entorno: 'production'"
    python importar_env_a_db.py .env.production production
fi

if [ -f ".env.sandbox" ]; then
    echo "Procesando archivo: '.env.sandbox' para el entorno: 'sandbox'"
    python importar_env_a_db.py .env.sandbox sandbox
fi

echo "✅ Proceso completado exitosamente!"