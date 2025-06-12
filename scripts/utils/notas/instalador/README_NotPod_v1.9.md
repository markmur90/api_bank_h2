
# NotPod v1.9

Suite de automatización personal con:

- Notas por texto y voz
- Resúmenes diarios/semanales
- Alertas por Telegram
- Backups con seguridad
- Crontab preconfigurado

---

## 📦 Instalación

```bash
sudo dpkg -i notpod_1.9_all.deb
```

---

## ⚙️ Activación post-instalación

```bash
crontab ~/.notpod/crontab.txt
```

---

## 📁 Scripts clave

| Script               | Función                                       |
|----------------------|-----------------------------------------------|
| `nota_texto.sh`      | Crear nota escrita                            |
| `nota_voz.sh`        | Grabar nota por voz                           |
| `resumen_dia.sh`     | Resumen de notas diario                       |
| `resumen_proyecto.sh`| Resumen semanal acumulado                     |
| `alerta_horaria.sh`  | Enviar alerta por Telegram cada 15 minutos    |
| `backup_and_sync.sh` | Respaldar al VPS (no borra archivos locales)  |
| `ver_notas.sh`       | Listar, editar y borrar notas interactivamente|
| `verificar_notpod.sh`| Diagnóstico de instalación                    |

---

## 🔧 Telegram

Archivo:
```bash
~/.notpod/telegram_config.sh
```

Con:
```bash
TG_TOKEN="..."
CHAT_ID="..."
```

Probar con:
```bash
enviar_telegram.sh "📬 Funciona"
```

---

## 🕒 Crontab (`~/.notpod/crontab.txt`)

```cron
*/15 * * * * /usr/local/bin/alerta_horaria.sh
@reboot /usr/local/bin/startup_sync.sh
0 23 * * * /usr/local/bin/resumen_dia.sh
0 22 * * 5 /usr/local/bin/resumen_proyecto.sh
30 2 * * * /usr/local/bin/daily_backup.sh
15 21 * * * /usr/local/bin/resumen_audio.sh
```

---

## 🗂️ Notas

Guardadas en:
```bash
~/.notpod/logs/notas/YYYY-MM-DD/
```

---

## 🧪 Verificación

```bash
verificar_notpod.sh
```

---

## Licencia

MIT
