# Arquitectura de la solución

1. **Django** se ejecuta en un puerto dinámico (>=8001).
2. **Nginx** (en 8000) hace SSL y proxy a Django.
3. **Tor** publica un Hidden Service apuntando al 8000.
4. **Ngrok** expone tu 8000 a Internet de forma segura.

## Cómo generar certificados SSL

```bash
mkdir -p /home/markmur88/local/config/certs
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /home/markmur88/local/config/certs/server.key \
  -out    /home/markmur88/local/config/certs/server.crt \
  -subj "/C=US/ST=State/L=City/O=Org/OU=Unit/CN=localhost"
