# forms.py
from django import forms
from .models import UrlMonitoreada

from django import forms
from .models import UrlMonitoreada

class EjecucionReconForm(forms.Form):
    MODO_CHOICES = [
        ('lista', 'Seleccionar URLs de la lista'),
        ('todas', 'Ejecutar en todas las URLs registradas'),
        ('manual', 'Ejecutar en una URL específica (General)'),
    ]

    CALCULO_CHOICES = [
        ('manual', 'Ingresar todo manualmente'),
        ('calcular_repeticiones', 'Calcular repeticiones (tiempo / espera)'),
        ('calcular_espera', 'Calcular espera (tiempo / repeticiones)'),
        ('calcular_tiempo', 'Calcular navegación (repeticiones × espera)'),
    ]

    modo = forms.ChoiceField(
        choices=MODO_CHOICES,
        widget=forms.RadioSelect,
        label="Modo de ejecución"
    )

    modo_calculo = forms.ChoiceField(
        choices=CALCULO_CHOICES,
        initial='manual',
        label="Modo de cálculo de parámetros"
    )

    urls = forms.ModelMultipleChoiceField(
        queryset=UrlMonitoreada.objects.none(),
        widget=forms.CheckboxSelectMultiple,
        required=False,
        label="URLs disponibles"
    )

    url_manual = forms.URLField(
        required=False,
        label="URL personalizada"
    )

    identificadores = forms.CharField(
        label="Identificadores",
        required=True,
        help_text="usuario, ip, correo, token, session_id, admin, debug, clave"
    )

    repeticiones = forms.IntegerField(
        initial=1,
        min_value=1,
        max_value=10,
        label="Repeticiones",
        help_text="Cuántas veces ejecutar max=10"
    )

    delay = forms.IntegerField(
        initial=10,
        min_value=1,
        label="Delay",
        help_text="Espera entre repeticiones (segundos)"
    )

    tiempo_navegacion = forms.IntegerField(
        initial=60,
        min_value=60,
        label="Tiempo de navegación",
        help_text="En segundos min=(60=1m) max=(1800=30m)"
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        qs = UrlMonitoreada.objects.all()
        self.fields['urls'].queryset = qs

    def clean(self):
        cleaned = super().clean()
        modo = cleaned.get("modo_calculo")
        tiempo = cleaned.get("tiempo_navegacion")
        delay = cleaned.get("delay")
        repeticiones = cleaned.get("repeticiones")

        try:
            if modo == "calcular_repeticiones":
                if not tiempo or not delay:
                    raise forms.ValidationError("Debes ingresar tiempo y delay.")
                cleaned["repeticiones"] = max(1, tiempo // delay)

            elif modo == "calcular_espera":
                if not tiempo or not repeticiones:
                    raise forms.ValidationError("Debes ingresar tiempo y repeticiones.")
                cleaned["delay"] = max(1, tiempo // repeticiones)

            elif modo == "calcular_tiempo":
                if not repeticiones or not delay:
                    raise forms.ValidationError("Debes ingresar repeticiones y delay.")
                cleaned["tiempo_navegacion"] = repeticiones * delay
        except ZeroDivisionError:
            raise forms.ValidationError("No puede haber división por cero en los cálculos.")

        return cleaned


import os
from django.conf import settings
import json
from django import forms

class UrlSeleccionForm(forms.Form):
    url = forms.ChoiceField(label="Selecciona una URL", widget=forms.Select(attrs={"class": "form-control"}))

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        with open(os.path.join(settings.BASE_DIR, "json", "ghost_config.json"), "r", encoding="utf-8") as f:
            data = json.load(f)
        self.fields['url'].choices = [(u, u) for u in data.get("urls", [])]
