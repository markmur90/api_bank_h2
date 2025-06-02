from django.conf import settings
from django.db import models
from django.contrib.auth.models import AbstractUser

class Usuario(AbstractUser):
    TEMA_CHOICES = [
        ("oscuro", "Oscuro"),
        ("claro", "Claro"),
    ]
    MODO_TOR_CHOICES = [
        ("backend", "Backend"),
        ("navegador", "Navegador"),
    ]

    tema = models.CharField(
        max_length=10,
        choices=TEMA_CHOICES,
        default="oscuro"
    )
    verificacion_tor = models.CharField(
        max_length=10,
        choices=MODO_TOR_CHOICES,
        default="backend"
    )

class PerfilUsuario(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )
    tema = models.CharField(
        max_length=10,
        choices=[("oscuro", "Oscuro"), ("claro", "Claro")]
    )

class IntentoReconocimiento(models.Model):
    fecha = models.DateTimeField(auto_now_add=True)
    url = models.URLField()
    identificadores = models.TextField()
    user_agent = models.CharField(max_length=512)
    reconocio = models.BooleanField()
    captura = models.ImageField(upload_to="capturas/")
    log = models.FileField(upload_to="logs/")
    request_headers = models.TextField(blank=True)
    response_headers = models.TextField(blank=True)
    notificado = models.BooleanField(default=False)
    tiempo_navegacion = models.IntegerField(
        default=60,
        help_text="Tiempo en segundos que se navegó en la URL"
    )

    def __str__(self):
        return f"Intento del {self.fecha.strftime('%Y-%m-%d %H:%M:%S')}"

class UrlMonitoreada(models.Model):
    url = models.URLField(unique=True)
    descripcion = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return self.url
