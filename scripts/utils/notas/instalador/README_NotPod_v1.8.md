
# NotPod v1.8

**NotPod** es una suite de automatización personal para:

- Toma de notas por texto y voz.
- Resúmenes diarios y semanales.
- Alertas automáticas por Telegram.
- Backups y sincronización programada.

---

## 📦 Instalación

```bash
sudo dpkg -i notpod_1.8_all.deb
```

---

## ⚙️ Activación post-instalación

```bash
crontab ~/.notpod/crontab.txt
```

Esto activa las tareas programadas.

---

## 📁 Scripts disponibles

| Script                        | Función                                       |
|-------------------------------|-----------------------------------------------|
| `nota_texto.sh`               | Guarda una nota escrita                       |
| `nota_voz.sh`                 | Graba nota de voz                             |
| `resumen_dia.sh`              | Muestra resumen diario                        |
| `resumen_proyecto.sh`         | Resumen extendido del proyecto                |
| `resumen_audio.sh`            | Notas de voz del día                          |
| `alerta_horaria.sh`           | Alerta cada 15 minutos vía Telegram           |
| `backup_and_sync.sh`          | Respaldo automático                           |
| `ver_notas.sh`                | Ver o buscar notas                            |
| `verificar_notpod.sh`         | Revisión de instalación                       |
| `enviar_telegram.sh`          | Envío manual de mensajes                      |
| `get_telegram_chat_id.sh`     | Detectar tu `chat_id`                         |
| `get_telegram_chat_id_test.sh`| Detectar y enviar test a Telegram             |

---

## 🔧 Telegram

Preconfigurado en:
```bash
~/.notpod/telegram_config.sh
```

Probar:
```bash
enviar_telegram.sh "✅ NotPod funcionando"
```

---

## 🔄 Crontab (`~/.notpod/crontab.txt`)

```cron
*/15 * * * * /usr/local/bin/alerta_horaria.sh
@reboot /usr/local/bin/startup_sync.sh
0 23 * * * /usr/local/bin/resumen_dia.sh >> ~/.notpod/logs/resumen_dia.log 2>&1
0 22 * * 5 /usr/local/bin/resumen_proyecto.sh >> ~/.notpod/logs/resumen_proyecto.log 2>&1
30 2 * * * /usr/local/bin/daily_backup.sh >> ~/.notpod/logs/backup.log 2>&1
15 21 * * * /usr/local/bin/resumen_audio.sh >> ~/.notpod/logs/audio.log 2>&1
```

---

## 🗂️ Ubicación de notas

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
