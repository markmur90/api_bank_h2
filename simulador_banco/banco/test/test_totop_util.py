import os
import django
import pytest

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'simulador_banco.simulador_banco.settings')
# Provide a dummy encryption key for tests
os.environ.setdefault('FIELD_ENCRYPTION_KEY', 'DbQG9CWLvBRa8Iu9pv9fJDVURCdKYQQErlZ9oCYGsY8=')

django.setup()

from banco import totp_utils

@pytest.mark.django_db
def test_verify_totp_roundtrip():
    code = totp_utils.pyotp.TOTP(totp_utils.get_totp_secret()).now()
    assert totp_utils.verify_totp(code) is True