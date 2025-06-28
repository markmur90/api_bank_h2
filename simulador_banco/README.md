# Simulador Bancario

Este repositorio contiene un proyecto Django minimalista que funciona como simulador de transferencias bancarias. Se incluyen servicios básicos de autenticación mediante JWT y operaciones de transferencia, además de un pequeño frontend de pruebas.

## Instalación rápida

1. Crear y activar un entorno virtual:
   ```bash
   python -m venv venv
   source venv/bin/activate
   pip install -r simulador_banco/requirements.txt
   ```
2. Copiar `.env.example` a `.env` y rellenar las variables requeridas:
   ```bash
   cp simulador_banco/.env.example simulador_banco/.env
   ```
   Las claves secretas **no** deben almacenarse en el repositorio.
3. Ejecutar migraciones y crear un superusuario:
   ```bash
   python simulador_banco/manage.py migrate
   python simulador_banco/manage.py createsuperuser
   ```
4. Iniciar el servidor de desarrollo:
   ```bash
   python simulador_banco/manage.py runserver
   ```

## Endpoint de transferencias entrantes

El proyecto expone `/api/transferencias/entrantes/` para recibir transferencias de sistemas externos. Es necesario autenticarse con JWT (ver `/api/token`). El cuerpo de la solicitud debe ser JSON y es procesado por `TransferService`.

## Pruebas manuales

- **Login**: acceder a `/` y autenticar con el superusuario creado.
- **Frontend de transferencia**: `/frontend/transfer` permite probar la obtención de token y el envío de transferencias.


Para un despliegue seguro revise la documentación existente en `docs/`.

## Integraciones externas

Defina las siguientes variables de entorno para habilitar las notificaciones y el análisis de transferencias:

```
TELEGRAM_BOT_TOKEN=<token del bot>
TELEGRAM_CHAT_ID=<chat id>
OPENAI_API_KEY=<clave de OpenAI>
TOTP_SECRET=<secreto base32 para OTP>
```

Para conectarse a la API externa defina también la URL base y las rutas
relativas utilizadas por el simulador:

```
BASE_URL=https://example.com
TOKEN_PATH=/oidc/token
AUTHORIZE_PATH=/oidc/authorize
OTP_PATH=/otp/single
AUTH_PATH=/auth/challenges
API_PATH=/payments
```


### ———————— OPENAI_API_KEY ————————

#### 1. Ve a tu cuenta de OpenAI: https://platform.openai.com/account/api-keys  

#### 2. Haz clic en “Create new secret key” y copia el valor que empieza por “sk-…”.  

#### 3. Exporta la variable en tu shell o en tu .env:

   export OPENAI_API_KEY="sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

### ———————— TOTP_SECRET ————————

Puedes generar un secreto Base32 con Python y la librería estándar:
Generamos 80 bits (10 bytes) y los codificamos en Base32, sin padding:

TOTP_SECRET=$(python3 - << 'EOF'
import secrets, base64
print(base64.b32encode(secrets.token_bytes(10)).decode('utf-8').rstrip('='))
EOF
)

export TOTP_SECRET="$TOTP_SECRET"

### Ejemplo de Uso

1. Añade estas líneas a tu ~/.bashrc o ~/.zshenv (o al .env de tu proyecto).

2. Recarga tu shell: source ~/.bashrc

3. Verifica que estén correctas:

   echo "OPENAI_API_KEY=$OPENAI_API_KEY"

   echo "TOTP_SECRET=$TOTP_SECRET"

### Entrega en pantalla la solución

   echo "Variables OPENAI_API_KEY y TOTP_SECRET configuradas correctamente."

Después de procesar una transferencia se enviará un mensaje a Telegram con el análisis generado por GPT‑4.

### Utilidad de generación de JWT

Para emitir un token JWT manualmente se incluye el comando de gestión
`generate_jwt`.  Ejecuta:

```bash
python simulador_banco/manage.py generate_jwt <usuario>
```

El secreto utilizado proviene de la variable de entorno `JWT_SECRET_KEY`.

