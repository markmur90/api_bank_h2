from .base1 import *

import environ
env = environ.Env()

env_file = BASE_DIR / ('.env.production' if DJANGO_ENV == 'production' else '.env.development')
env.read_env(env_file)

SECRET_KEY = env('SECRET_KEY')
DEBUG = env.bool('DEBUG', default=False)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])



DATABASES = {
    'default': env.db('DATABASE_URL')
}





