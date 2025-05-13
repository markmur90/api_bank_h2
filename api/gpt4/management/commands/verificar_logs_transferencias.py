import os
from django.core.management.base import BaseCommand
from django.conf import settings
from api.gpt4.models import Transfer, LogTransferencia
from api.gpt4.utils import registrar_log, obtener_ruta_schema_transferencia

LOG_DIR = os.path.join(settings.BASE_DIR, 'LOGS', 'transferencias')

class Command(BaseCommand):
    help = 'Verifica que cada transferencia tenga logs correspondientes en archivo y base de datos.'

    def handle(self, *args, **kwargs):
        transferencias = Transfer.objects.all()
        faltantes = []

        for t in transferencias:
            pid = t.payment_id
            base_path = os.path.join(LOG_DIR, f"transferencia_{pid}.log")
            carpeta = obtener_ruta_schema_transferencia(pid)

            archivos_esperados = {
                'archivo_log': os.path.exists(base_path),
                'pain001': os.path.exists(os.path.join(carpeta, f"pain001_{pid}.xml")),
                'aml': os.path.exists(os.path.join(carpeta, f"aml_{pid}.xml")),
            }

            logs_db = LogTransferencia.objects.filter(registro=pid)
            tipos_presentes = set(logs_db.values_list('tipo_log', flat=True))

            tipos_requeridos = {'TRANSFER', 'XML', 'AML'}
            if t.auth_id:
                tipos_requeridos.add('OTP')
            if t.client:
                tipos_requeridos.add('AUTH')

            logs_faltantes = tipos_requeridos - tipos_presentes
            archivos_faltantes = [k for k, existe in archivos_esperados.items() if not existe]

            if logs_faltantes or archivos_faltantes:
                resultado = f"Faltantes para {pid}:\n"
                if archivos_faltantes:
                    resultado += f" - Archivos: {', '.join(archivos_faltantes)}\n"
                if logs_faltantes:
                    resultado += f" - Logs DB: {', '.join(logs_faltantes)}\n"
                self.stdout.write(self.style.WARNING(resultado))

                registrar_log(
                    pid,
                    tipo_log='ERROR',
                    error="Transferencia incompleta",
                    extra_info=f"Archivos faltantes: {archivos_faltantes}, Logs DB faltantes: {logs_faltantes}"
                )

                faltantes.append(pid)

        self.stdout.write(self.style.SUCCESS(f"Verificación completa. Transferencias con problemas: {len(faltantes)}"))
