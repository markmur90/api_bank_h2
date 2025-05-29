from django.db import models

class ConfiguracionAPI(models.Model):
    ENTORNOS = [
        ("production", "Producción"),
        ("sandbox", "Sandbox"),
        ("local", "Local"),
    ]

    entorno = models.CharField(max_length=20, choices=ENTORNOS, default="production")
    nombre = models.CharField(max_length=100)
    valor = models.TextField()
    descripcion = models.TextField(blank=True)
    activo = models.BooleanField(default=True)

    class Meta:
        unique_together = ("entorno", "nombre")
        ordering = ['entorno', 'nombre']

    def __str__(self):
        return f"[{self.entorno.upper()}] {self.nombre}"