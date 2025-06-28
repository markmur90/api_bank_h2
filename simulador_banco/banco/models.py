from django.db import models
from django.contrib.auth.hashers import make_password, check_password
from django.core.files.base import ContentFile
from django.utils import timezone
import uuid

class OficialBancario(models.Model):
    username = models.CharField(max_length=50, unique=True)
    password_hash = models.CharField(max_length=128)

    def set_password(self, raw_password):
        self.password_hash = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password_hash)

    def __str__(self):
        return self.username

    class Meta:
        app_label = 'banco'
        
class OTPChallenge(models.Model):
    payment_id = models.CharField(max_length=100)
    challenge_id = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    otp = models.CharField(max_length=6)
    transfer_data = models.JSONField(null=True, blank=True)
    status = models.CharField(max_length=20, default="CREATED")
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.payment_id} - {self.challenge_id}"

    class Meta:
        app_label = 'banco'


# models.py

"""
MIT License

Copyright (c) 2025 TuEmpresa

Permission is hereby granted, free of charge, to any person obtaining a copy...
"""

from django.db import models
from django.contrib.auth.hashers import make_password, check_password
from django.core.validators import RegexValidator, MinValueValidator
from django.utils import timezone
from django.conf import settings
from cryptography.fernet import Fernet, InvalidToken
from django.utils.encoding import force_bytes, force_str
import uuid
from decimal import Decimal

# ------------------------------------------------------------------------------
# UTILIDADES DE CIFRADO (sin cambios)
# ------------------------------------------------------------------------------
class EncryptedCharField(models.Field):
    description = "CharField cifrado con AES256+HMAC"
    def __init__(self, *args, **kwargs):
        kwargs.setdefault('max_length', 255)
        super().__init__(*args, **kwargs)
        keys = getattr(settings, 'FIELD_ENCRYPTION_KEYS', None)
        if not keys:
            key = getattr(settings, 'FIELD_ENCRYPTION_KEY', None)
            if not key:
                raise RuntimeError("Define FIELD_ENCRYPTION_KEY en settings.py")
            keys = [key]
        self.fernets = [Fernet(k) for k in keys]
    def get_prep_value(self, value):
        if value is None:
            return None
        token = self.fernets[0].encrypt(force_bytes(value))
        return token.decode()
    def from_db_value(self, value, expression, connection):
        if value is None:
            return None
        last_error = None
        for f in self.fernets:
            try:
                return force_str(f.decrypt(force_bytes(value)))
            except InvalidToken as e:
                last_error = e
                continue
        raise last_error
    def db_type(self, connection):
        return 'text'

# ------------------------------------------------------------------------------
# VALIDADORES (sin cambios)
# ------------------------------------------------------------------------------
country_validator = RegexValidator(
    regex=r'^[A-Z]{2}$',
    message='Código de país ISO 3166-1 alpha-2, e.g. “DE”, “ES”'
)
iban_validator = RegexValidator(
    regex=r'^[A-Z]{2}[0-9A-Z]{13,32}$',
    message='IBAN inválido'
)
currency_validator = RegexValidator(
    regex=r'^[A-Z]{3}$',
    message='Código de moneda ISO 4217, e.g. “EUR”, “USD”'
)

# ------------------------------------------------------------------------------
# CLASES ABSTRACTAS
# ------------------------------------------------------------------------------
class PostalAddress(models.Model):
    country = models.CharField(max_length=2, validators=[country_validator])
    street = models.CharField(max_length=70)
    city = models.CharField(max_length=70)
    class Meta:
        db_table = 'sim_postal_address'
        app_label = 'banco'
    def __str__(self):
        return f"{self.country} {self.street} {self.city}"

class Party(models.Model):
    name = models.CharField(max_length=70, unique=True)
    address = models.OneToOneField(
        PostalAddress,
        on_delete=models.CASCADE,
        related_name="%(class)ss_address"
    )
    class Meta:
        abstract = True
        app_label = 'banco'
        
    def __str__(self):
        return self.name

class Account(models.Model):
    iban = EncryptedCharField(
        max_length=34, unique=True,
        validators=[iban_validator],
        help_text="IBAN cifrado"
    )
    currency = models.CharField(
        max_length=3, default='EUR',
        validators=[currency_validator]
    )
    
    class Meta:
        abstract = True
        app_label = 'banco'
        
    def __str__(self):
        return self.iban

# ------------------------------------------------------------------------------
# MODELOS CONCRETOS (Meta hereda de la clase padre)
# ------------------------------------------------------------------------------
class Debtor(Party):
    customer_id = models.CharField(max_length=35, unique=True)

    class Meta(Party.Meta):
        db_table = 'sim_debtor'
        app_label = 'banco'

class DebtorAccount(Account):
    debtor = models.ForeignKey(
        Debtor, on_delete=models.CASCADE,
        related_name='accounts'
    )
    balance = models.DecimalField(
        max_digits=18, decimal_places=2,
        default=Decimal('0.00'),
    )

    class Meta(Account.Meta):
        db_table = 'sim_debtor_account'
        app_label = 'banco'

class AccountMovement(models.Model):
    """Movimientos de saldo para cuentas reales."""

    DEPOSIT = 'DEPOSIT'
    PAYMENT = 'PAYMENT'
    TYPE_CHOICES = [
        (DEPOSIT, 'Depósito'),
        (PAYMENT, 'Pago'),
    ]

    account = models.ForeignKey(
        DebtorAccount,
        on_delete=models.CASCADE,
        related_name='movimientos'
    )
    tipo = models.CharField(max_length=10, choices=TYPE_CHOICES)
    monto = models.DecimalField(max_digits=12, decimal_places=2)
    fecha = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.pk:
            if self.tipo == self.DEPOSIT:
                self.account.balance += self.monto
            else:
                self.account.balance -= self.monto
            self.account.save()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.account} {self.tipo} {self.monto}"

    class Meta:
        app_label = 'banco'


class Creditor(Party):
    class Meta(Party.Meta):
        db_table = 'sim_creditor'
        app_label = 'banco'
        
        
class CreditorAccount(Account):
    creditor = models.ForeignKey(
        Creditor, on_delete=models.CASCADE,
        related_name='accounts'
    )

    class Meta(Account.Meta):
        db_table = 'sim_creditor_account'
        app_label = 'banco'

class CreditorAgent(models.Model):
    """Agente financiero intermedio."""
    bic = models.CharField(max_length=11, unique=True)
    financial_institution_id = models.CharField(max_length=35, unique=True)
    other_information = models.CharField(max_length=70, blank=True)

    def __str__(self):
        return self.bic

    class Meta:
        db_table = 'sim_creditor_agent'
        app_label = 'banco'

class PaymentIdentification(models.Model):
    """Identificadores internos de la transacción."""
    end_to_end_id = models.CharField(max_length=35)
    instruction_id = models.CharField(max_length=35)

    def __str__(self):
        return self.end_to_end_id

    class Meta:
        db_table = 'sim_payment_identification'
        app_label = 'banco'

class ClientID(models.Model):
    codigo = models.CharField(max_length=6, primary_key=True)
    client_id = models.CharField(max_length=60, unique=True, blank=True, null=True)

    def __str__(self):
        return f"{self.codigo} – {self.client_id}"

    class Meta:
        db_table = 'sim_client_id'
        app_label = 'banco'

class Kid(models.Model):
    codigo = models.CharField(max_length=6, primary_key=True)
    kid = models.CharField(max_length=60, unique=True)

    def __str__(self):
        return f"{self.codigo} - {self.kid}"

    class Meta:
        db_table = 'sim_kid'
        app_label = 'banco'

class Transfer(models.Model):
    # campos...
    payment_id = models.CharField(max_length=36, unique=True, db_index=True)
    # relaciones...
    debtor = models.ForeignKey(Debtor, on_delete=models.PROTECT, related_name='transfers')
    creditor = models.ForeignKey(Creditor, on_delete=models.PROTECT, related_name='transfers')
    debtor_account = models.ForeignKey(DebtorAccount, on_delete=models.PROTECT)
    creditor_account = models.ForeignKey(CreditorAccount, on_delete=models.PROTECT)
    creditor_agent = models.ForeignKey('CreditorAgent', on_delete=models.PROTECT)
    instructed_amount = models.DecimalField(
        max_digits=18, decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    currency = models.CharField(max_length=3, default='EUR', validators=[currency_validator])
    purpose_code = models.CharField(max_length=4, default='GDSV')
    requested_execution_date = models.DateField()
    remittance_information_unstructured = models.CharField(max_length=140, blank=True, null=True)
    status = models.CharField(
        max_length=10,
        choices=[
            ('CREA','Creada'), ('PDNG','Pendiente'), ('ACSP','En Proceso'),
            ('ACSC','Ejecutada'), ('RJCT','Rechazada'), ('CANC','Cancelada'),
            ('ERRO','Error')
        ],
        default='CREA', db_index=True
    )
    payment_identification = models.ForeignKey('PaymentIdentification', on_delete=models.CASCADE)
    auth_id = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'sim_transfer'
        ordering = ['-created_at']
        app_label = 'banco'
        
    def to_schema_data(self):
        return {
            "purposeCode": self.purpose_code or "GDSV",
            "requestedExecutionDate": self.requested_execution_date.strftime('%Y-%m-%d'),
            "debtor": {
                "debtorName": self.debtor.name,
                "debtorPostalAddress": {
                    "country": self.debtor.address.country,
                    "addressLine": {
                        "streetAndHouseNumber": self.debtor.address.street,
                        "zipCodeAndCity": self.debtor.address.city,
                    }
                }
            },
            "debtorAccount": {
                "iban": self.debtor_account.iban,
                "currency": self.debtor_account.currency,
            },
            "paymentIdentification": {
                "instructionId": self.payment_identification.instruction_id,
                "endToEndId": self.payment_identification.end_to_end_id
            },
            "instructedAmount": {
                "amount": float(self.instructed_amount),
                "currency": self.currency,
            },
            "creditorAgent": {
                "financialInstitutionId": self.creditor_agent.financial_institution_id or "",
            },
            "creditor": {
                "creditorName": self.creditor.name,
                "creditorPostalAddress": {
                    "country": self.creditor.address.country,
                    "addressLine": {
                        "streetAndHouseNumber": self.creditor.address.street,
                        "zipCodeAndCity": self.creditor.address.city,
                    }
                }
            },
            "creditorAccount": {
                "iban": self.creditor_account.iban,
                "currency": self.creditor_account.currency,
            },
            "remittanceInformationUnstructured": self.remittance_information_unstructured or ""
        }

    def get_status_color(self):
        return {
            'PDNG': 'warning',
            'ACSC': 'success',
            'RJCT': 'danger',
            'CANC': 'secondary'
        }.get(self.status, 'dark')

    def __str__(self):
        return self.payment_id


class LogTransferencia(models.Model):
    """Registro de eventos del flujo de transferencia."""
    registro = models.CharField(
        max_length=64,
        help_text="Puede ser payment_id o session_id"
    )
    tipo_log = models.CharField(
        max_length=20,
        choices=[
            ('AUTH','Autenticación'),
            ('TRANSFER','Transferencia'),
            ('XML','Generación XML'),
            ('AML','Generación AML'),
            ('ERROR','Error'),
            ('SCA','Autenticación Fuerte'),
            ('OTP','Generación OTP'),
        ]
    )
    contenido = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'sim_log_transferencia'
        ordering = ['-created_at']
        app_label = 'banco'
        verbose_name = 'Log de Transferencia'
        verbose_name_plural = 'Logs de Transferencias'

    def __str__(self):
        timestamp = self.created_at.strftime('%Y-%m-%d %H:%M:%S')
        return f"{self.tipo_log} – {self.registro} – {timestamp}"
