#!/bin/bash

set -e

INSTALL_PATH="/home/markmur88/.local/share/notas"
BIN_PATH="/home/markmur88/.local/bin"
mkdir -p "$INSTALL_PATH"
mkdir -p "$BIN_PATH"

# Copiar archivos
echo "[INFO] Copiando archivos a $INSTALL_PATH..."
cp -r notas/* "$INSTALL_PATH"

# Añadir alias a .zshrc si no existe
if ! grep -q "alias_notas.sh" "/home/markmur88/.zshrc"; then
    echo 'source "/home/markmur88/.local/share/notas/alias_notas.sh"' >> "/home/markmur88/.zshrc"
    echo "[INFO] Alias añadidos a .zshrc"
fi

# Instalar crontab
crontab "$INSTALL_PATH/crontab.txt"
echo "[INFO] Crontab instalado"

# Crear acceso directo en ~/.local/bin
echo '#!/bin/bash' > "$BIN_PATH/notas"
echo 'bash "/home/markmur88/.local/share/notas/notas_menu.sh" "$@"' >> "$BIN_PATH/notas"
chmod +x "$BIN_PATH/notas"

echo "[✔] Instalación completada. Abre una nueva terminal o ejecuta 'source ~/.zshrc'"
