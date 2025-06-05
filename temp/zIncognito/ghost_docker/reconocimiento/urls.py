from django.urls import path, reverse_lazy
from . import views
from django.contrib.auth.views import LoginView, LogoutView

urlpatterns = [
    path("", views.dashboard, name="ghostrecon_home"),
    path("intentos/", views.lista_intentos, name="lista_intentos"),
    path("<int:pk>/", views.detalle_intento, name="detalle_intento"),
    path("exportar/", views.exportar_pdf, name="exportar_pdf"),
    path("login/", LoginView.as_view(
        template_name='login.html',
        redirect_authenticated_user=True
    ), name='login'),
    path("logout/", LogoutView.as_view(next_page=reverse_lazy('login')), name='logout'),
    path("dashboard/", views.dashboard, name="dashboard"),
    path("seleccionar/", views.seleccionar_url, name="seleccionar_url"),
    path("ejecutar/", views.ejecutar_reconocimiento, name="ejecutar_recon"),
    path("dashboard/intentos/", views.intentos_recientes_json, name="intentos_json"),
    path("dashboard/notificar/", views.marcar_notificado, name="notificar_intentos"),
    path("api/ultimos_intentos/", views.ultimos_intentos_json, name="ultimos_intentos_json"),
    path("reinicio-seguro/", views.reinicio_seguro, name="reinicio_seguro"),

]
