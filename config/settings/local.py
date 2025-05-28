from .base1 import *

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Configuraciones específicas del entorno local
USE_OAUTH2_UI = False

REDIRECT_URI = os.getenv("REDIRECT_URI", "http://0.0.0.0:8000/oauth2/callback/")
ORIGIN = os.getenv("ORIGIN", "http://0.0.0.0:8000")

OAUTH2.update({
    "REDIRECT_URI": REDIRECT_URI,
    "ORIGIN": ORIGIN,
})
