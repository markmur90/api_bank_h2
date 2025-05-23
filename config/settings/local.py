from .base1 import *

import os
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = env('SECRET_KEY')
DEBUG = env.bool('DEBUG', default=True)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['0.0.0.0', '127.0.0.1', 'localhost'])

DATABASES = {
    'default': env.db('DATABASE_URL')
}

CORS_ORIGIN_ALLOW_ALL = True
CORS_ALLOW_CREDENTIALS = True