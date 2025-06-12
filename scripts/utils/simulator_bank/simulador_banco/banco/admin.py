from django.contrib import admin
from .models import DebtorSimulado, CreditorSimulado, TransferenciaSimulada

@admin.register(DebtorSimulado)
class DebtorSimuladoAdmin(admin.ModelAdmin):
    list_display = ("id", "nombre")

@admin.register(CreditorSimulado)
class CreditorSimuladoAdmin(admin.ModelAdmin):
    list_display = ("id", "nombre")

@admin.register(TransferenciaSimulada)
class TransferenciaSimuladaAdmin(admin.ModelAdmin):
    list_display = ("payment_id", "debtor", "creditor", "monto", "fecha")
    list_filter = ("fecha",)
    search_fields = ("payment_id", "debtor__nombre", "creditor__nombre")
