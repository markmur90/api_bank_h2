# 📦 Notas Instalador - Linux

Este paquete `.deb` instala un conjunto de scripts para automatización de notas, backups y alertas usando `bash`, `cron`, `dialog` y alias en `zsh`.

## ✅ Requisitos
- Linux
- `zsh`, `dialog`, `cron`
- Acceso SSH configurado

## 🚀 Instalación
```bash
sudo dpkg -i notas-inst_1.0_all.deb
```

Luego, ejecutá:
```bash
notas_menu
```

## ⚙️ Configuración
Durante la instalación se genera un archivo:
```
~/.config/notas_instalador/config.conf
```

## 📋 Menú de uso
Llamá `notas_menu` para ver un selector interactivo con `dialog`.

## 🧼 Desinstalación
```bash
bash uninstall_notas.sh
```

## 📁 Contenido
- Scripts `.sh`
- Alias automáticos
- Tareas programadas (`cron`)
