
# 🚀 Script Maestro de Despliegue – CoreTransAPI / Ghost Recon

Este repositorio contiene el sistema automatizado de despliegue para múltiples entornos, incluyendo:

- Heroku (`api_bank_heroku`)
- VPS Njalla (`coretransact`)
- Entorno de reconocimiento blindado (`ghost_recon`)

Todos los scripts están en la carpeta `scripts/` y son orquestados por `master_final_unico_a.sh`.

---

## 📦 Requisitos previos

- Bash >= 5.x
- Acceso a SSH con clave
- Docker (opcional)
- Acceso a Njalla y Heroku configurado

---

## 🎯 Uso del script maestro

```bash
chmod +x master_final_unico_a.sh
./master_final_unico_a.sh [parámetros]
```

---

## 🧩 Parámetros disponibles

| Parámetro | Acción                                        | Script                      |
|-----------|-----------------------------------------------|-----------------------------|
| `-a`      | Ejecuta todos los scripts                     | TODOS                       |
| `-d`      | Diagnóstico del entorno                       | 01_diagnose.sh              |
| `-r`      | Verificación de puertos                       | 02_ports.sh                 |
| `-c`      | Contenedores activos                          | 03_containers.sh            |
| `-u`      | Actualización del sistema                     | 04_update_system.sh         |
| `-f`      | Firewall UFW                                  | 05_ufw.sh                   |
| `-m`      | Cambio MAC                                    | 06_macchanger.sh            |
| `-t`      | Inicio de Tor                                 | 07_tor.sh                   |
| `-k`      | Limpieza de backups zip                       | 08_clean_zip.sh             |
| `-p`      | Instalación PostgreSQL                        | 09_postgres.sh              |
| `-x`      | Reset de base de datos PostgreSQL             | 10_reset_postgres.sh        |
| `-g`      | Migraciones Django                            | 11_migrations.sh            |
| `-s`      | Creación de superusuario                      | 12_user.sh                  |
| `-l`      | Carga de fixtures                             | 13_loaddata.sh              |
| `-e`      | Generación de claves PEM                      | 14_pem.sh                   |
| `-z`      | Backup comprimido ZIP                         | 15_zip_backup.sh            |
| `-b`      | Backup local                                  | 16_backup_local.sh          |
| `-y`      | Sincronización entre entornos                 | 17_sync.sh                  |
| `-v`      | Configuración SSL, Supervisor, Nginx          | 18_ssl_nginx.sh             |
| `-n`      | Inicio Gunicorn                               | 19_gunicorn.sh              |
| `-h`      | Despliegue Heroku                             | 20_deploy_heroku.sh         |
| `-j`      | Despliegue a VPS Njalla                       | 21_deploy_njalla.sh         |
| `-o`      | Verificación de acceso vía Tor                | 22_tor_web.sh               |
| `-q`      | Notificación final                            | 23_notify.sh                |
| `-i`      | Subida de proyectos con rsync                 | 24_rsync_project.sh         |
| `-w`      | Actualización de DNS dinámico en Njalla       | 25_update_ddns_njalla.sh    |

---

## 🔧 Flujos de ejecución recomendados

### 🚀 Despliegue a Heroku

```bash
./master_final_unico_a.sh -u -g -s -l -h -q
```

### 🛰️ Despliegue inicial al VPS (coretransact)

```bash
./master_final_unico_a.sh -d -r -u -f -m -p -g -s -l -n -v -j -i -w -q
```

### 🛡️ Actualización blindada (Tor + SSH)

```bash
./master_final_unico_a.sh -t -o -i -w -y -q
```

---

## 🗂 Estructura del repositorio

```
.
├── master_final_unico_a.sh       # Script maestro
├── scripts/                      # Todos los scripts automatizados
├── config/                       # Archivos de configuración systemd y nginx
├── README.md                     # (este archivo)
```

---

## 🧠 Notas finales

- Usa `-a` solo cuando quieras ejecutar absolutamente todo (inicialización completa).
- Personaliza el script `21_deploy_njalla.sh` con tu lógica de despliegue y Gunicorn/Nginx.
- La sincronización DNS con Njalla requiere que configures un subdominio dinámico y su clave.

---
