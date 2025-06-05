from django.urls import path, reverse_lazy
from django.contrib.auth.views import LoginView, LogoutView

from reconocimiento.views import cambiar_modo_tor, cambiar_tema, dashboard, detalle_intento, ejecutar_reconocimientoC, exportar_pdf, lista_intentos, marcar_notificado, obtener_ip_publica, reiniciar_identidad_tor, reinicio_seguro, seleccionar_url, set_nav, ultimos_intentos_json, verificar_tor

urlpatterns = [
    path("", dashboard, name="ghostrecon_home"),
    path("intentos/", lista_intentos, name="lista_intentos"),
    path("<int:pk>/", detalle_intento, name="detalle_intento"),
    path("exportar/", exportar_pdf, name="exportar_pdf"),
    path("login/", LoginView.as_view(
        template_name='login.html',
        redirect_authenticated_user=True
    ), name='login'),
    path("logout/", LogoutView.as_view(next_page=reverse_lazy('login')), name='logout'),
    path("dashboard/", dashboard, name="dashboard"),
    path("seleccionar/", seleccionar_url, name="seleccionar_url"),
    path("ejecutar/", ejecutar_reconocimientoC, name="ejecutar_recon"),
    
    path("dashboard/notificar/", marcar_notificado, name="notificar_intentos"),
    path("api/ultimos_intentos/", ultimos_intentos_json, name="ultimos_intentos_json"),
    
    
    path("reinicio-seguro/", reinicio_seguro, name="reinicio_seguro"),
    path("tor/nueva-identidad/", reiniciar_identidad_tor, name="reiniciar_identidad_tor"),
    path("api/verificar_tor/", verificar_tor, name="verificar_tor"),
    path("api/ip_publica/", obtener_ip_publica, name="ip_publica"),
    path("cambiar-tema/", cambiar_tema, name="cambiar_tema"),
    path("cambiar-verificacion-tor/", cambiar_modo_tor, name="cambiar_verificacion_tor"),
    path('set-nav/', set_nav, name='set_nav'),

]
