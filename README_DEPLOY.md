# 🧠 Automatización de Despliegue — `api_bank_h2`

Este archivo documenta el uso de funciones Bash para automatizar el despliegue, configuración y ejecución del sistema `api_bank_h2` en distintos entornos. Incluye alias funcionales para `local`, `heroku`, `production`, y pruebas SSL.

---

## 🧩 VARIABLES DE CONTROL

| Parámetro(s)                  | Variable interna         | Descripción                                                             |
|------------------------------|---------------------------|-------------------------------------------------------------------------|
| `-a` \| `--all`              | `PROMPT_MODE=false`       | Ejecutar todos los pasos sin confirmaciones                             |
| `-s` \| `--step`             | `PROMPT_MODE=true`        | Modo paso a paso                                                        |
| `-W` \| `--dry-run`          | `DRY_RUN=true`            | Modo simulación: no realiza acciones destructivas                       |
| `-d` \| `--debug`            | `DEBUG_MODE=true`         | Activa modo diagnóstico extendido                                       |

---

## 🧰 TAREAS DE DESARROLLO LOCAL

| Parámetro(s)                  | Variable interna         | Descripción                                                             |
|------------------------------|---------------------------|-------------------------------------------------------------------------|
| `-L` \| `--do-local`         | `DO_JSON_LOCAL=true`      | Cargar archivos locales `.json` y `.env`                                |
| `-l` \| `--do-load-local`    | `DO_RUN_LOCAL=true`       | Ejecutar entorno local estándar                                         |
| `-r` \| `--do-local-ssl`     | `DO_LOCAL_SSL=true`       | Ejecutar entorno local con SSL (Gunicorn + Nginx 8443)                  |

---

## 💾 BACKUPS Y DEPLOY

| Parámetro(s)                  | Variable interna             | Descripción                                                           |
|------------------------------|-------------------------------|-----------------------------------------------------------------------|
| `-C` \| `--do-clean`         | `DO_CLEAN=true`               | Limpiar respaldos antiguos                                            |
| `-Z` \| `--do-zip`           | `DO_ZIP_SQL=true`             | Generar backups ZIP + SQL                                             |
| `-B` \| `--do-bdd`           | `DO_SYNC_REMOTE_DB=true`      | Sincronizar BDD remota                                                |
| `-H` \| `--do-heroku`        | `DO_HEROKU=true`              | Desplegar a Heroku                                                    |
| `-v` \| `--do-vps`           | `DO_DEPLOY_VPS=true`          | Desplegar a VPS (Njalla)                                              |
| `-S` \| `--do-sync`          | `DO_SYNC_LOCAL=true`          | Sincronizar archivos locales                                          |

---

## 🛠 ENTORNO Y CONFIGURACIÓN

| Parámetro(s)                  | Variable interna         | Descripción                                                             |
|------------------------------|---------------------------|-------------------------------------------------------------------------|
| `-Y` \| `--do-sys`           | `DO_SYS=true`             | Actualizar sistema y dependencias                                      |
| `-P` \| `--do-ports`         | `DO_PORTS=true`           | Cerrar puertos abiertos conflictivos                                   |
| `-D` \| `--do-docker`        | `DO_DOCKER=true`          | Diagnóstico y soporte Docker                                           |
| `-M` \| `--do-mac`           | `DO_MAC=true`             | Cambiar dirección MAC aleatoria                                        |
| `-x` \| `--do-ufw`           | `DO_UFW=true`             | Configurar firewall UFW                                                |
| `-p` \| `--do-pem`           | `DO_PEM=true`             | Generar claves PEM locales                                             |
| `-U` \| `--do-create-user`   | `DO_USER=true`            | Crear usuario del sistema                                              |
| `-u` \| `--do-varher`        | `DO_VARHER=true`          | Configurar variables Heroku                                            |

---

## 🗃️ POSTGRES Y MIGRACIONES

| Parámetro(s)                  | Variable interna         | Descripción                                                             |
|------------------------------|---------------------------|-------------------------------------------------------------------------|
| `-Q` \| `--do-pgsql`         | `DO_PGSQL=true`           | Configurar conexión PostgreSQL                                          |
| `-I` \| `--do-migra`         | `DO_MIG=true`             | Aplicar migraciones Django                                              |

---

## 🌐 EJECUCIÓN Y TESTING

| Parámetro(s)                  | Variable interna             | Descripción                                                           |
|------------------------------|-------------------------------|-----------------------------------------------------------------------|
| `-G` \| `--do-gunicorn`      | `DO_GUNICORN=true`            | Ejecutar Gunicorn como servidor                                       |
| `-w` \| `--do-web`           | `DO_RUN_WEB=true`             | Abrir navegador tras despliegue                                       |
| `-V` \| `--do-verif-trans`   | `DO_VERIF_TRANSF=true`        | Verificar transferencias SEPA                                         |
| `-E` \| `--do-cert`          | `DO_CERT=true`                | Generar certificados autofirmados                                     |

---

## 🚀 Comandos Disponibles

### Funciones generales

| Comando        | Parámetros     | Descripción                                            |
|----------------|----------------|--------------------------------------------------------|
| `d_help`       | `--help`       | Muestra ayuda del script maestro                      |
| `d_step`       | `-s`           | Ejecuta paso a paso                                   |
| `d_all`        | `-a`           | Ejecuta todos los bloques disponibles                 |
| `d_debug`      | `-d`           | Activa modo debug                                     |
| `d_menu`       | `--menu`       | Muestra menú interactivo con FZF                      |
| `d_status`     | —              | Diagnóstico completo del entorno actual               |

---

## 🌐 Entorno Local

| Comando             | Parámetros                                                       | Descripción                                      |
|---------------------|------------------------------------------------------------------|--------------------------------------------------|
| `d_local`           | `-P -D -M -x -C -Z -Q -I -L -S -V -p -u -H -B -v -E`              | Versión resumida de despliegue local + SSL      |
| `d_local_long`      | `--do-*` largo para cada acción                                 | Versión larga, explícita, con todas las acciones|
| `d_local_dry`       | `--dry-run -P -C -Q -I -U -V`                                    | Simulación del despliegue local                 |
| `d_local_dry_long`  | `--dry-run --do-*` largo                                        | Simulación con todos los pasos largos           |
| `d_local_ssl`       | —                                                               | Ejecuta entorno local HTTPS (Nginx + Gunicorn)  |
| `d_ssl`             | —                                                               | Servidor HTTPS para desarrollo (runsslserver)   |

---

## ☁️ Entorno Heroku

| Comando         | Parámetros                         | Descripción                              |
|-----------------|------------------------------------|------------------------------------------|
| `d_heroku`      | `-P -C -u -U -V -p -x`             | Despliegue completo en Heroku            |
| `d_heroku_long` | `--do-*` largo                    | Versión detallada del despliegue Heroku  |

---

## 🛡 Entorno Producción (Njalla / VPS)

| Comando                   | Parámetros                              | Descripción                                           |
|---------------------------|-----------------------------------------|-------------------------------------------------------|
| `d_njalla`                | `-P -C -H -U -V -u -B -v`                | Despliegue total en producción con verificación       |
| `d_njalla_long`           | `--do-*` largo                         | Versión completa detallada para producción Njalla     |
| `d_production_vars`       | `-P -C -H -U -V`                         | Solo pasos críticos de producción                     |
| `d_production_vars_long`  | `--do-*` largo                         | Versión larga de pasos críticos                       |
| `d_prod_min`              | `-v -V`                                  | Despliegue mínimo: deploy y ejecución web             |
| `d_prod_min_long`         | `--do-deploy-vps --do-run-web`         | Versión explícita del despliegue mínimo               |

---

## 🧪 Ejemplos de Uso

```bash
d_local                         # Ejecuta entorno local completo + SSL
d_local --dry-run -d            # Simulación en modo debug
d_heroku --do-cert              # Heroku + certificados
d_njalla -a                     # Producción Njalla con todos los pasos
```

---

## 📂 Recomendación

Agrega este archivo a tu `.bashrc`, `.bash_aliases` o `.zshrc` y luego ejecuta:

```bash
source ~/.bash_aliases
```

Así tendrás acceso inmediato a todas las funciones.
