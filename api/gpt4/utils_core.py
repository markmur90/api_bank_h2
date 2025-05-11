import os
from pathlib import Path
from config import settings
from cryptography.hazmat.primitives import serialization

BASE_DIR = Path(__file__).resolve().parent.parent

def get_project_path(*rel_path: str | Path) -> str:
    return str(BASE_DIR.joinpath(*rel_path))

def load_private_key_y_kid():
    path = Path(settings.PRIVATE_KEY_PATH)
    if not path.exists():
        raise FileNotFoundError(f"Clave privada no encontrada: {path}")
    key = path.read_bytes()
    try:
        private_key = serialization.load_pem_private_key(key, password=None)
    except Exception as e:
        raise ValueError(f"Error cargando la clave privada: {e}")
    kid = getattr(settings, "PRIVATE_KEY_KID", None)
    if not kid:
        raise ValueError("PRIVATE_KEY_KID no definido en settings.")
    return private_key, kid
