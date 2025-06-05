from django.urls import path
from .views import recibir_transferencia

urlpatterns = [
    path("recibir/", recibir_transferencia, name="recibir_transferencia"),
]
