from django.db import models

class DebtorSimulado(models.Model):
    nombre = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.nombre

class CreditorSimulado(models.Model):
    nombre = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.nombre

class TransferenciaSimulada(models.Model):
    payment_id = models.CharField(max_length=100)
    debtor = models.ForeignKey(DebtorSimulado, on_delete=models.CASCADE)
    creditor = models.ForeignKey(CreditorSimulado, on_delete=models.CASCADE)
    monto = models.DecimalField(max_digits=12, decimal_places=2)
    fecha = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.payment_id} - {self.monto} EUR"




from django.db import models
from django.contrib.auth.hashers import make_password, check_password

class OficialBancario(models.Model):
    username = models.CharField(max_length=50, unique=True)
    password_hash = models.CharField(max_length=128)

    def set_password(self, raw_password):
        self.password_hash = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password_hash)
