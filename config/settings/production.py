from .base1 import *

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Configuraciones específicas del entorno de producción
USE_OAUTH2_UI = True

REDIRECT_URI = os.getenv("REDIRECT_URI", "https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/")
ORIGIN = os.getenv("ORIGIN", "https://apibank2-54644cdf263f.herokuapp.com")

OAUTH2.update({
    "REDIRECT_URI": REDIRECT_URI,
    "ORIGIN": ORIGIN,
})
