# config/settings/__init__.py

import os

DJANGO_ENV = os.getenv("DJANGO_ENV", "local").lower()

if DJANGO_ENV == "heroku":
    from .heroku import *
elif DJANGO_ENV == "sandbox":
    from .sandbox import *
elif DJANGO_ENV == "production":
    from .production import *
else:
    from .local import *

print(f"[settings] DJANGO_ENV = {DJANGO_ENV} → usando {DJANGO_ENV}.py")
