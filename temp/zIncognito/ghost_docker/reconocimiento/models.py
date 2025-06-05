from django.db import models

# models.py

class IntentoReconocimiento(models.Model):
    fecha = models.DateTimeField(auto_now_add=True)
    url = models.URLField()
    identificadores = models.TextField()
    user_agent = models.CharField(max_length=512)
    reconocio = models.BooleanField()
    captura = models.ImageField(upload_to="media/capturas/")
    log = models.FileField(upload_to="media/logs/")
    request_headers = models.TextField(blank=True)
    response_headers = models.TextField(blank=True)
    notificado = models.BooleanField(default=False)
    tiempo_navegacion = models.IntegerField(default=60, help_text="Tiempo en segundos que se navegó en la URL")
    
    def __str__(self):
        return f"Intento del {self.fecha.strftime('%Y-%m-%d %H:%M:%S')}"





class UrlMonitoreada(models.Model):
    url = models.URLField(unique=True)
    descripcion = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return self.url
