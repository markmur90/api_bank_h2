import os
import django
import pytest

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'simulador_banco.simulador_banco.settings')
os.environ.setdefault('FIELD_ENCRYPTION_KEY', 'DbQG9CWLvBRa8Iu9pv9fJDVURCdKYQQErlZ9oCYGsY8=')
django.setup()

from banco.models import Debtor, DebtorAccount, PostalAddress, AccountMovement

@pytest.mark.django_db
def test_account_movement_updates_balance():
    addr = PostalAddress.objects.create(country="ES", street="Calle", city="Madrid")
    debtor = Debtor.objects.create(name="Alice", customer_id="C1", address=addr)
    account = DebtorAccount.objects.create(debtor=debtor, iban="ES1234567890123", currency="EUR")
    AccountMovement.objects.create(account=account, tipo=AccountMovement.DEPOSIT, monto=50)
    account.refresh_from_db()
    assert account.balance == 50
    