#!/bin/bash

# crear_paquete.sh
# Script para generar un .deb del gestor de tareas con zenity y libnotify

set -e

PAQUETE="gestor-tareas"
VERSION="1.0"
ARCH="all"
DEST="./${PAQUETE}_${VERSION}.deb"

mkdir -p ${PAQUETE}/DEBIAN
mkdir -p ${PAQUETE}/usr/local/bin

# Copiar el script principal
cp gestor_tareas.sh ${PAQUETE}/usr/local/bin/
chmod 755 ${PAQUETE}/usr/local/bin/gestor_tareas.sh

# Crear archivo de control
cat <<EOF > ${PAQUETE}/DEBIAN/control
Package: ${PAQUETE}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: zenity, libnotify-bin
Maintainer: Tu Nombre <tu.email@example.com>
Description: Gestor de tareas con recordatorios, zenity y notificaciones de escritorio.
EOF

# Construir paquete
dpkg-deb --build ${PAQUETE}

# Renombrar con nombre amigable
mv ${PAQUETE}.deb ${DEST}

# Checksum para verificación
sha256sum ${DEST} > ${DEST}.sha256

echo "✅ Paquete creado: ${DEST}"
cat ${DEST}.sha256
