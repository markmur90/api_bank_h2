import sys
import os
from pathlib import Path

# Ensure the project package is importable when running tests.
BASE = Path(__file__).resolve().parent / 'simulador_banco'
sys.path.insert(0, str(BASE))

# Django settings rely on the 'banco' app name. Provide an alias so that
# ``INSTALLED_APPS`` can reference ``'banco'`` even though the actual module
# lives inside ``simulador_banco``.


# Minimal environment variables required for settings.
os.environ.setdefault('FIELD_ENCRYPTION_KEY', 'DbQG9CWLvBRa8Iu9pv9fJDVURCdKYQQErlZ9oCYGsY8=')
os.environ.setdefault('SECRET_KEY', 'secret')
os.environ.setdefault('JWT_SECRET_KEY', 'jwt')
os.environ.setdefault('TOKEN_URL', 'https://example.com/token')
os.environ.setdefault('AUTHORIZE_URL', 'https://example.com/authorize')
os.environ.setdefault('OTP_URL', 'https://example.com/otp')
os.environ.setdefault('AUTH_URL', 'https://example.com/auth')
os.environ.setdefault('API_URL', 'https://example.com/api')
os.environ.setdefault('SIMULATOR_NOTIFY_URL', 'http://localhost/notify')
os.environ.setdefault('TOTP_SECRET', 'JBSWY3DPEHPK3PXP')