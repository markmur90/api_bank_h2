# 🚀 Despliegue Profesional - `api_bank_heroku` (VPS Njalla)

Este documento describe cómo desplegar y mantener el proyecto `api_bank_heroku` en un entorno de producción seguro (VPS Njalla) usando `Gunicorn`, `Supervisor`, `Nginx` y entorno virtual Python.

---

## 📦 Estructura General

```
api_bank_heroku/
├── .env.production
├── config/
│   ├── settings/
│   │   ├── base1.py
│   │   ├── production.py
├── scripts/
│   ├── 01_full.sh
│   ├── 21_deploy_njalla.sh
│   ├── configurar_gunicorn.sh
│   ├── verificar_https_headers.sh
│   ├── vps_instalar_dependencias.sh
```

---

## ⚙️ Despliegue por primera vez

```bash
bash ./scripts/01_full.sh --env=production --do-clean --do-zip --do-pgsql --do-migra --do-deploy-vps --do-gunicorn --do-run-web
```

---

## 🔁 Actualizaciones posteriores

```bash
bash ./scripts/01_full.sh --env=production --do-zip --do-deploy-vps --do-run-web
```

---

## 👁 Verificar headers HTTPS

```bash
bash ./scripts/verificar_https_headers.sh
```

---

## 🔐 Servicios de producción

- Gunicorn: sirve la app Django
- Supervisor: gestiona Gunicorn como servicio
- Nginx: servidor proxy reverso y HTTPS
