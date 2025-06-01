import jwt
from datetime import datetime, timezone, timedelta

SECRET_KEY = 'bar1588623'

payload = {
    'sub': 'DE86500700100925993805',
    'name': 'MIRYA TRADING CO LTD',
    'iat': datetime.now(timezone.utc),
    'exp': datetime.now(timezone.utc) + timedelta(hours=24)
}

token = jwt.encode(payload, SECRET_KEY, algorithm='ES256')

with open('generated_token_jwt.txt', 'w') as token_file:
    token_file.write(token)

print(f"Generated JWT Token: {token}")
