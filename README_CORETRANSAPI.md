
# 🛡️ Proyecto VPS CoreTransAPI

Este README documenta la configuración y despliegue del entorno de producción sobre el VPS provisto por Njalla, utilizando seguridad reforzada y despliegue automatizado para una API bancaria.

---

## 🌐 Dominio y Servidor

- **Dominio:** `coretransapi.com` (administrado en Njalla)
- **VPS:** Debian 12 (VPS 15) - `504e1ebc.host.njalla.net`
- **IP pública:** `80.78.30.188`
- **IPv6:** `2a0a:3840:8078:30::504e:1ebc:1337`
- **Hostname:** `coretransapi`

---

## 🔐 Seguridad

- **SSH Key (ed25519)**: Acceso únicamente con clave pública
- **Puerto SSH personalizado:** 49222
- **Firewall:** UFW activado + reglas específicas
- **Protección adicional:** fail2ban + acceso recomendado vía VPN + Tor

---

## 📦 Scripts de instalación

Ubicados en el directorio `scripts/`, estos scripts automatizan el setup del VPS:

| Script                                 | Función                                      |
|----------------------------------------|----------------------------------------------|
| `setup_coretransact.sh`               | Script maestro de configuración inicial      |
| `vps_instalar_dependencias.sh`        | Instala dependencias necesarias              |
| `vps_configurar_ssh.sh`               | Configura claves y puerto SSH                |
| `vps_configurar_sistema.sh`           | Timezone, hostname y usuario                 |
| `vps_deploy_django.sh`                | Clonación y despliegue de Django             |
| `vps_configurar_gunicorn.sh`          | Configura Gunicorn para Django               |
| `vps_configurar_nginx.sh`             | Configura Nginx con SSL                      |

---

## 📡 Configuración DNS Njalla

- Crear un registro A para `api.coretransapi.com` apuntando a `80.78.30.188`.
- TTL: `3600`
- Activar DNSSEC y configurar glue records si aplica.

---

## 🔒 Certificados SSL

Certbot se encargará de emitir los certificados:

```bash
certbot --nginx -d api.coretransapi.com
```

Los certificados estarán en:

```nginx
ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
```

---

## ⚙️ Bloque nginx.conf para producción

```nginx
server {
    listen 80;
    server_name api.coretransapi.com;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 📌 Recomendaciones

- Utilizar claves cifradas y backup en USB offline.
- Registrar toda conexión saliente con logs individuales (ping, OTP, SEPA).
- Usar fail2ban, honeypot y rotación de logs.

---

© `markmur88` – CoreTransAPI Deployment Guide
