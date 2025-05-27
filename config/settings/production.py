
from .base1 import *

DEBUG = False
ALLOWED_HOSTS = ['apibank2-54644cdf263f.herokuapp.com', 'apih.coretransapi.com']
SECRET_KEY = "MX2QfdeWkTc8ihotA_i1Hm7_4gYJQB4oVjOKFnuD6Cw"

ENVIRONMENT = 'production'
DJANGO_ENV = 'production'

DATABASE_URL = "postgres://u22qfesn1ol61g:p633435fd268a16298ff6b2b83e47e7091ae5cb79d80ad13e03a6aff1262cc2ae@c7pvjrnjs0e7al.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/ddo6kmmjfftuav"
DATABASES = {
    'default': dj_database_url.parse(DATABASE_URL)
}

USE_OAUTH2_UI = True
REDIRECT_URI = 'https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/'
ORIGIN = 'https://apibank2-54644cdf263f.herokuapp.com'

OAUTH2.update({
    "REDIRECT_URI": REDIRECT_URI,
    "ORIGIN": ORIGIN,
})
PRIVATE_KEY_PATH = os.path.join(BASE_DIR, 'schemas/keys/private_key.pem')
PRIVATE_KEY_KID = '7ed9e904-a421-4d49-8e9d-4a453b2d63c8'
