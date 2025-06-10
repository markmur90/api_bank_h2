#!/bin/bash

# ==============================================================================
# SCRIPT PARA RESTAURAR BASE DE DATOS Y SUBIR VARIABLES DE ENTORNO
# ==============================================================================
#
# ESTE SCRIPT REALIZA DOS ACCIONES PRINCIPALES:
#
# 1. BORRA la base de datos existente y la RESTAURA desde un archivo .sql.
#    ¡¡¡CUIDADO: ESTA ACCIÓN ES DESTRUCTIVA!!!
#
# 2. SUBE las variables de los archivos .env a la tabla 'configuraciones_api'.
#
# INSTRUCCIONES:
# 1. Coloca este script, 'backup_local.sql', y tus archivos .env en el mismo
#    directorio.
# 2. Edita las variables de conexión a continuación si es necesario.
# 3. Otorga permisos de ejecución: chmod +x restore_and_upload.sh
# 4. Ejecuta el script: ./restore_and_upload.sh
#
# ==============================================================================

# --- CONFIGURACIÓN ---
DB_USER="markmur88"
DB_PASSWORD="Ptf8454Jd55"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="mydatabase"
BACKUP_FILE="backup_local.sql"

# Salir inmediatamente si un comando falla
set -e

# --- PASO 1: RESTAURANDO LA BASE DE DATOS ---
echo "--- PASO 1: RESTAURANDO LA BASE DE DATOS DESDE '$BACKUP_FILE' ---"

# Exporta la contraseña para que los comandos de psql/dropdb/createdb no la pidan
export PGPASSWORD=$DB_PASSWORD

# Comprobar si el archivo de backup existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: No se encontró el archivo de respaldo '$BACKUP_FILE'. Abortando."
    exit 1
fi

echo "Eliminando la base de datos antigua '$DB_NAME' (si existe)..."
dropdb --if-exists -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"

echo "Creando una base de datos limpia '$DB_NAME'..."
createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"

echo "Restaurando la base de datos..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$BACKUP_FILE" --quiet

echo "✅ Restauración completada."
echo ""


# --- PASO 2: SUBIENDO ARCHIVOS .ENV ---
echo "--- PASO 2: SUBIENDO VARIABLES DESDE ARCHIVOS .ENV ---"

# Función para procesar cada archivo .env (borra e inserta)
procesar_archivo_env() {
    local archivo="$1"
    local entorno

    case "$archivo" in
        *.env.production) entorno="production" ;;
        *.env.local) entorno="local" ;;
        *) entorno="local" ;;
    esac

    echo "----------------------------------------------------"
    echo "Procesando archivo: '$archivo' para el entorno: '$entorno'"
    
    # Borra las configuraciones antiguas para este entorno
    echo "Borrando configuraciones antiguas para el entorno '$entorno'..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
    "DELETE FROM configuraciones_api WHERE entorno = '$entorno';" --quiet

    # Lee el archivo línea por línea para insertar los nuevos datos
    while IFS= read -r linea || [[ -n "$linea" ]]; do
        if [[ -z "$linea" || "$linea" =~ ^# ]]; then
            continue
        fi

        nombre=$(echo "$linea" | cut -d '=' -f 1 | xargs)
        valor=$(echo "$linea" | cut -d '=' -f 2-)
        valor="${valor#\"}"
        valor="${valor%\"}"
        valor_escapado=$(echo "$valor" | sed "s/'/''/g")

        echo "Subiendo: $nombre"
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
        "INSERT INTO configuraciones_api (entorno, nombre, valor, descripcion, activo) VALUES ('$entorno', '$nombre', '$valor_escapado', '', true);" \
        --quiet
    done < "$archivo"
    echo "----------------------------------------------------"
}

# Ejecución principal para la subida de .env
ARCHIVOS_ENV=(".env" ".env.local" ".env.production")

for archivo in "${ARCHIVOS_ENV[@]}"; do
    if [ -f "$archivo" ]; then
        procesar_archivo_env "$archivo"
    else
        echo "Advertencia: No se encontró el archivo '$archivo', se omitirá."
    fi
done


# Limpiar la variable de entorno de la contraseña
unset PGPASSWORD
set +e

echo ""
echo "✅ Proceso combinado completado con éxito."