# Supervisor de servicio local

Esta carpeta gestiona tu servicio Django en `0.0.0.0:8000` junto con Nginx, Tor, SSL y Ngrok, todo bajo `/home/markmur88/local`.

## Instalación

1. **Clona** o copia este directorio en `/home/markmur88/local`.  
2. **Genera** tus certificados SSL (ver `docs/architecture.md`).  
3. En `config/ngrok.yml`, añade tu `authtoken`.  
4. Da permisos de ejecución al script:
   ```bash
   chmod +x /home/markmur88/local/scripts/manage.sh
