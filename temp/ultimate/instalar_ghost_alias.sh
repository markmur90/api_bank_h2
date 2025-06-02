#!/bin/bash

echo -e "\n🔧 Instalador de Ghost Recon Ultimate - v1.0.0\n"

# Configuración
ENTORNO="env_ghost"
SCRIPT="ultimate_ghost.py"
REQUIREMENTS="requirements.txt"
ALIAS="ghostrun"
ALIAS_LINE="alias $ALIAS='source \$(pwd)/$ENTORNO/bin/activate && python3 \$(pwd)/$SCRIPT'"
SHELL_RC="$HOME/.bashrc"
[ "$SHELL" == */zsh ] && SHELL_RC="$HOME/.zshrc"

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo -e "❌ Python3 no está instalado."
    exit 1
fi

# Crear entorno virtual
if [ ! -d "$ENTORNO" ]; then
    echo -e "🐍 Creando entorno virtual: $ENTORNO"
    python3 -m venv "$ENTORNO"
else
    echo -e "📦 Entorno virtual ya existe."
fi

source "$ENTORNO/bin/activate"

# Crear requirements.txt si no existe
if [ ! -f "$REQUIREMENTS" ]; then
    echo -e "📄 Generando $REQUIREMENTS"
    cat <<EOF > "$REQUIREMENTS"
# Requisitos para Ghost Recon Ultimate
requests==2.31.0
playwright==1.44.0
EOF
fi

# Instalar dependencias
echo -e "📥 Instalando dependencias..."
pip install -r "$REQUIREMENTS"
echo -e "🌐 Instalando navegador Firefox para Playwright..."
python -m playwright install firefox

# Crear carpetas necesarias
mkdir -p logs capturas cache logs/red

# Crear README.md
echo -e "📝 Creando README.md..."
cat <<EOF > README.md
# 🕵️ Ghost Recon Ultimate

Ghost Recon Ultimate es una herramienta de navegación anónima, detección de rastros web y rotación de identidad IP/MAC a través de la red Tor. Perfecta para análisis OSINT, fingerprinting y pruebas de evasión.

## 🚀 Instalación

```bash
./instalar_ghost.sh
Esto creará el entorno virtual, instalará los navegadores y configurará un alias `ghostrun`.
🧪 Ejemplos

Modo automático:
```bash
ghostrun https://objetivo.com login,password 3 10 test_01
```

Modo manual:
```bash
ghostrun https://web.com email,password intentoA --manual --tiempo=4m
```

Cambio de red:
```bash
ghostrun --setup-red=eth0
```
📁 Estructura de archivos generados

    `logs/log_*.txt` → HTML, cookies, user-agent

    `capturas/captura_*.png` → capturas del sitio

    `logs/red/` y `cache/` → info IP/MAC y registros de red

🧩 Requisitos

    Python 3.8+

    Navegador Firefox (instalado automáticamente)

    Tor en ejecución en 127.0.0.1:9050

💀 Autor

markmur88 — 2025
EOF
Alias permanente

if ! grep -Fxq "$ALIAS_LINE" "$SHELL_RC"; then
echo -e "🔗 Agregando alias persistente: $ALIAS → $SCRIPT"
echo -e "\n# Ghost Recon Alias" >> "$SHELL_RC"
echo "$ALIAS_LINE" >> "$SHELL_RC"
echo -e "✅ Alias creado. Ejecuta: source $SHELL_RC"
else
echo -e "🧠 Alias $ALIAS ya está configurado."
fi

echo -e "\n✅ Instalación completa."
echo -e "🕵️ Ejecuta: ghostrun --help"
echo -e "📖 Lee README.md para ejemplos y guía completa."


---

### 📦 Resultado tras ejecutarlo

- 🐍 `env_ghost/` con entorno listo
- 📦 `requirements.txt` generado o respetado
- 📁 `logs/`, `capturas/`, `cache/`, `logs/red/`
- 🧠 Alias `ghostrun` creado (solo recarga shell)
- 📝 `README.md` con toda la documentación
- 🧼 ¡Todo en un solo comando!

---

¿Deseas también que incluya verificación de que `tor` esté corriendo antes de instalar o ejecutar? ¿O que genere una versión `.deb` instalable?
