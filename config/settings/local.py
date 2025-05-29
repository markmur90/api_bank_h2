# from config.settings.configuración_dinamica import OAUTH2
from .base1 import *

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Configuraciones específicas del entorno local
USE_OAUTH2_UI = False

REDIRECT_URI = os.getenv("REDIRECT_URI", "https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/")
ORIGIN = os.getenv("ORIGIN", "https://apibank2-54644cdf263f.herokuapp.com")

OAUTH2.update({
    "REDIRECT_URI": REDIRECT_URI,
    "ORIGIN": ORIGIN,
})

DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"