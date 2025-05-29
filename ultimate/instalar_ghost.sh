#!/bin/bash

echo -e "\n🔧 Instalador de Ghost Recon Ultimate\n"

# Nombre del entorno
ENTORNO="env_ghost"

# Requisitos mínimos
REQUIREMENTS="requirements.txt"

# Verifica Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "❌ Python3 no está instalado. Instálalo primero."
    exit 1
fi

# Crea entorno virtual
if [ ! -d "$ENTORNO" ]; then
    echo -e "🐍 Creando entorno virtual: $ENTORNO"
    python3 -m venv "$ENTORNO"
else
    echo -e "📦 Entorno virtual ya existe: $ENTORNO"
fi

# Activar entorno
source "$ENTORNO/bin/activate"

# Crear requirements si no existe
if [ ! -f "$REQUIREMENTS" ]; then
    echo -e "📄 Creando requirements.txt"
    cat <<EOF > "$REQUIREMENTS"
# Requisitos para Ghost Recon Ultimate
requests==2.31.0
playwright==1.44.0
EOF
fi

# Instalar dependencias
echo -e "📥 Instalando dependencias desde $REQUIREMENTS..."
pip install -r "$REQUIREMENTS"

# Instalar navegadores necesarios
echo -e "🌐 Instalando navegador Firefox para Playwright..."
python -m playwright install firefox

# Crear carpetas si no existen
mkdir -p logs capturas cache logs/red

echo -e "\n✅ Instalación completada."
echo -e "🚀 Ejecuta el script con: source $ENTORNO/bin/activate && python3 ultimate_ghost.py --help"
echo -e "📁 Carpetas preparadas: logs/, capturas/, cache/\n"
