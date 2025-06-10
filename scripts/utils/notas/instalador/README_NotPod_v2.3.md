
# NotPod v2.3

**NotPod** es una suite de automatización personal que permite:

- Crear notas por texto y voz
- Generar resúmenes diarios y semanales
- Enviar alertas por Telegram
- Realizar backups automáticos al VPS
- Configurar PostgreSQL local y remoto
- TODO centralizado y configurable en `.env`

---

## 🧠 Instalación Interactiva

```bash
sudo dpkg -i notpod_2.3_all.deb
```

Durante la instalación vas a configurar:

- 📍 Carpeta base (`~/notas`, `~/Documentos/notas`, etc.)
- 🔑 Telegram: `TG_TOKEN`, `CHAT_ID`
- 🧑‍💻 VPS: usuario, IP, ruta remota, clave SSH
- 💾 Local: carpeta de respaldo
- 🐘 PostgreSQL: usuario, password y base local/VPS
- ⏱️ Frecuencias: cada cuántos minutos/hora ejecutar tareas

Toda esta configuración queda guardada en:
```bash
<tu carpeta>/notas/.env
```

---

## ✅ Activación

Después de instalar:

```bash
crontab <carpeta>/notas/crontab.txt
```

---

## 📁 Scripts incluidos

| Script               | Función                                       |
|----------------------|-----------------------------------------------|
| `nota_texto.sh`      | Crear nota escrita                            |
| `nota_voz.sh`        | Grabar nota de voz                            |
| `resumen_dia.sh`     | Resumen diario                                |
| `resumen_proyecto.sh`| Resumen semanal                               |
| `alerta_horaria.sh`  | Enviar alerta periódica por Telegram          |
| `backup_and_sync.sh` | Respaldar archivos al VPS                     |
| `ver_notas.sh`       | Listar, ver, editar y borrar notas            |
| `verificar_notpod.sh`| Diagnóstico de instalación                    |
| `enviar_telegram.sh` | Envío manual de mensajes                      |

---

## 📂 Notas

Las notas se guardan en:
```bash
<carpeta>/notas/logs/notas/YYYY-MM-DD/
```

---

## 🧪 Verificación

```bash
verificar_notpod.sh
```

---

## Licencia

MIT
