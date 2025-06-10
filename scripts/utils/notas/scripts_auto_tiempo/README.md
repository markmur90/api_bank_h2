# Scripts de Automatización

Incluye:
- `backup_and_sync.sh`: Respalda base y proyecto, sincroniza con VPS y limpia datos locales.
- `alerta_acumulada.sh`: Lleva control horario de trabajo y genera resumen diario y total.
- `resumen_audio.sh`: Lee en voz alta los tiempos acumulados.

## Instrucciones

1. Dar permisos de ejecución:
```bash
chmod +x *.sh
```

2. Agregar al `crontab` con:
```bash
crontab crontab.txt
```
