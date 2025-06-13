#!/bin/bash

# ==============================================================================
# SCRIPT PARA SUBIR VARIABLES DE ENTORNO A POSTGRESQL (CON BORRADO)
# ==============================================================================
# Este script lee archivos .env, BORRA las configuraciones antiguas para ese
# entorno y luego inserta las nuevas en la tabla 'configuraciones_api'.
#
# INSTRUCCIONES:
# 1. Edita las variables de conexión a la base de datos a continuación.
# 2. Asegúrate de que el cliente de psql esté instalado.
# 3. Otorga permisos de ejecución al script: chmod +x upload_env_to_postgres.sh
# 4. Ejecuta el script: ./upload_env_to_postgres.sh
# ==============================================================================

# --- CONFIGURACIÓN DE LA BASE DE DATOS ---
# (Extraído de tu DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase")
DB_USER="markmur88"
DB_PASSWORD="Ptf8454Jd55"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="mydatabase"

# --- FUNCIÓN PARA PROCESAR CADA ARCHIVO .ENV ---
procesar_archivo_env() {
    local archivo="$1"
    local entorno

    # Determinar el entorno basado en el nombre del archivo
    case "$archivo" in
        *.env.production)
            entorno="production"
            ;;
        *.env.local)
            entorno="local"
            ;;
        *)
            # Para el archivo .env genérico, asumimos 'local' o podrías cambiarlo
            entorno="local"
            ;;
    esac

    echo "----------------------------------------------------"
    echo "Procesando archivo: '$archivo' para el entorno: '$entorno'"
    echo "----------------------------------------------------"

    # Exporta la contraseña para que psql la use sin pedirla
    export PGPASSWORD=$DB_PASSWORD
    
    # --- BORRADO DE DATOS ANTIGUOS ---
    # Borra todas las entradas existentes para este entorno para evitar duplicados.
    echo "Borrando configuraciones antiguas para el entorno '$entorno'..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
    "DELETE FROM configuraciones_api WHERE entorno = '$entorno';" \
    --quiet

    # Lee el archivo línea por línea para insertar los nuevos datos
    while IFS= read -r linea || [[ -n "$linea" ]]; do
        # Ignorar líneas vacías y comentarios (que empiezan con #)
        if [[ -z "$linea" || "$linea" =~ ^# ]]; then
            continue
        fi

        # Extraer el nombre (key) y el valor (value)
        nombre=$(echo "$linea" | cut -d '=' -f 1)
        valor=$(echo "$linea" | cut -d '=' -f 2-)

        # Limpiar espacios en blanco del nombre
        nombre=$(echo "$nombre" | xargs)

        # Quitar comillas opcionales del inicio y final del valor
        valor="${valor#\"}"
        valor="${valor%\"}"

        # Escapar comillas simples (') para la consulta SQL, reemplazándolas por ('')
        valor_escapado=$(echo "$valor" | sed "s/'/''/g")

        echo "Subiendo: $nombre"

        # Construir y ejecutar el comando SQL INSERT
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
        "INSERT INTO configuraciones_api (entorno, nombre, valor, descripcion, activo) VALUES ('$entorno', '$nombre', '$valor_escapado', '', true);" \
        --quiet

    done < "$archivo"

    # Limpiar la variable de entorno de la contraseña
    unset PGPASSWORD
}

# --- EJECUCIÓN PRINCIPAL ---
ARCHIVOS_ENV=(".env.local" ".env.production")

for archivo in "${ARCHIVOS_ENV[@]}"; do
    if [ -f "$archivo" ]; then
        procesar_archivo_env "$archivo"
    else
        echo "Advertencia: No se encontró el archivo '$archivo', se omitirá."
    fi
done

echo ""
echo "✅ Proceso completado."