import jwt
from datetime import datetime, timedelta

SECRET_KEY = 'clave_secreta_bien_larga_123456'
ALGORITHM = 'HS256'

payload = {
    'user': 'admin',
    'exp': datetime.utcnow() + timedelta(hours=1)
}

token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
print(token)
