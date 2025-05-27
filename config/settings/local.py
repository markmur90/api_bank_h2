
from .base1 import *

DEBUG = True
SECRET_KEY = "MX2QfdeWkTc8ihotA_i1Hm7_4gYJQB4oVjOKFnuD6Cw"
ALLOWED_HOSTS = ['127.0.0.1', '0.0.0.0']

DJANGO_ENV = 'local'
ENVIRONMENT = 'local'

DATABASE_URL = 'postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase'
DATABASES = {
    'default': dj_database_url.parse(DATABASE_URL)
}

SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False
SECURE_SSL_REDIRECT = False

USE_OAUTH2_UI = True
REDIRECT_URI = 'http://0.0.0.0:8000/oauth2/callback/'
ORIGIN = 'http://localhost:8000'


OAUTH2.update({
    "REDIRECT_URI": REDIRECT_URI,
    "ORIGIN": ORIGIN,
})