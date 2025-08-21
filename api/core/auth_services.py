import requests
from config import settings
from api.configuraciones_api.helpers import get_conf

def get_simulator_token(username: str, password: str) -> str:
    url = get_conf("TOKEN_ENDPOINT")  # Usar TOKEN_ENDPOINT del .env.production
    payload = {"username": username, "password": password}
    resp = requests.post(url, json=payload, headers={"Content-Type":"application/json"})
    resp.raise_for_status()
    return resp.json().get("token")
