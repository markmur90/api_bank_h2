# 💸 Simulador Bancario SEPA — Proyecto de Ascenso

Este entorno emula un sistema bancario con soporte de transferencias SEPA, validación de IP segura, conexión vía DNS bancario, y un servidor simulado accesible tanto por IP pública como por la red Tor.

---

## ⚙️ Requisitos

- Python 3.10+
- Tor instalado y corriendo
- Supervisor + Gunicorn + NGINX en el VPS
- Puerto 9080 libre (o configurable)
- Acceso SSH root al VPS

---

## 🚀 Despliegue en VPS

1. Subí y ejecutá el script:
```bash
scp deploy_simulador.sh root@504e1ef2.host.njalla.net:/root/
ssh root@504e1ef2.host.njalla.net
chmod +x deploy_simulador.sh
./deploy_simulador.sh
```

2. Activá como servicio persistente:
```bash
scp simulador_banco_logs.service root@504e1ef2.host.njalla.net:/etc/systemd/system/simulador_banco.service
systemctl daemon-reload
systemctl enable simulador_banco
systemctl start simulador_banco
```

3. Monitoreo en tiempo real:
```bash
./monitor_logs.sh
```

---

## 🧅 Activar Servicio Tor (.onion)

```bash
scp configurar_tor_onion.sh root@504e1ef2.host.njalla.net:/root/
ssh root@504e1ef2.host.njalla.net
chmod +x configurar_tor_onion.sh
./configurar_tor_onion.sh
```

- `.onion` generado en: `/var/lib/tor/hidden_simulador/hostname`

Para activarlo en cada reinicio:
```bash
scp tor_simulador_onion.service root@504e1ef2.host.njalla.net:/etc/systemd/system/
systemctl daemon-reload
systemctl enable tor_simulador_onion
```

---

## 🛠️ Variables .env sugeridas (en local)

```env
DNS_BANCO=80.78.30.242
DOMINIO_BANCO=504e1ef2.host.njalla.net
RED_SEGURA_PREFIX=193.150.168.
MOCK_PORT=9080
ALLOW_FAKE_BANK=true
API_URL=http://504e1ef2.host.njalla.net:9080/api/gpt4/recibir/
```

---

## 🔍 Verificación IP en código

- `conexion_banco.py` usa `get_conf()` para:
  - Validar red segura
  - Resolver DNS bancario
  - Conectarse por fallback local si `ALLOW_FAKE_BANK=true`

---

## 🧪 Desde Interfaz Web

- Usar vista `send_transfer_view` (`send_transfer.html`)
- Activar `usar_conexion_banco` en la sesión
- Enviar transferencia y ver logs remotos

---

## 📂 Archivos Clave

- `deploy_simulador.sh`: Instala entorno Django+Gunicorn
- `simulador_banco.service`: Servicio systemd persistente
- `configurar_tor_onion.sh`: Monta nuevo servicio oculto Tor
- `tor_simulador_onion.service`: Ejecuta eso como servicio

---

## 📞 Soporte

Contacto interno: `funcionario-dev-corebank@ejemplo.com`  
Responsable: _MarkMur88_
