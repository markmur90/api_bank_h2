# Módulo de Conexión Segura — Deutsche Bank

Este módulo `conexion_banco.py` permite detectar si estás en la red privada del banco
y realizar conexiones HTTPS seguras con resolución DNS personalizada.

## Variables de entorno

- ALLOW_FAKE_BANK=true — permite conexiones a un servidor mock local (127.0.0.1)

## Uso

from conexion_banco import hacer_request_seguro

response = hacer_request_seguro("internet.dbbank-de", path="/api/estado", metodo="GET")

## Requisitos

- `dnspython`
- `requests`
- archivo `.env` con la variable ALLOW_FAKE_BANK
- función auxiliar `registrar_log(módulo, mensaje)` accesible desde `api.gpt4.utils`
