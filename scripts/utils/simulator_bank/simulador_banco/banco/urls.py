
from django.urls import path

from scripts.utils.simulator_bank.simulador_banco.banco.api_login import login_api_simulador
from . import views

urlpatterns = [
    path('api/transferencia/', views.recibir_transferencia, name='api_transferencia'),
    path('', views.login_view, name='login'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('transferencia/', views.transferencia_view, name='transferencia'),
    path('registro/', views.registro_view, name='registro'),
    path('api/token', views.generar_token),
    path("api/login/", login_api_simulador),

]
