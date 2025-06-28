import json
import jwt
from datetime import datetime, timezone, timedelta

SECRET_KEY = 'bar1588623'

payload = {
    'sub': 'DE86500700100925993805',
    'name': 'MIRYA TRADING CO LTD',
    'iat': datetime.now(timezone.utc),
    'exp': datetime.now(timezone.utc) + timedelta(hours=24)
}

token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')

with open('token.txt', 'w') as tf:
    tf.write(token)
with open('token.json', 'w') as jf:
    json.dump({'access_token': token}, jf)
print(f"Generated JWT Token: {token}")
