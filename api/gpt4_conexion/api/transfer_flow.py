# heroku/api/gpt4_conexion/api/transfer_flow.py
from django.views import View
from django.http import JsonResponse
from django.conf import settings
import pyotp

from .config import TRANSFER_ENDPOINT, VERIFY_OTP_ENDPOINT
from bank_connector import BankConnector
from api.gpt4.utils import generar_xml_pain001, registrar_log
from api.utils.jwt_simulador import generar_token_simulador

class TransferView(View):
    connector = BankConnector()

    def post(self, request):
        # 1) Parseo y preparación de datos
        data = request.json()
        payment_id = data.get('payment_id')
        xml = generar_xml_pain001(data)
        registrar_log(payment_id, tipo_log="TRANSFER_INIT")

        # 2) Obtener JWT dinámico para el Simulador
        token = generar_token_simulador(settings.SIM_USER)
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }

        try:
            # 3) Petición inicial de transferencia
            resp1 = self.connector.send(
                TRANSFER_ENDPOINT,
                json={'xml': xml},
                headers=headers
            )
            registrar_log(payment_id, tipo_log="TRANSFER_REQUESTED", extra_info=str(resp1))

            # 4) Si se requiere OTP/TOTP, generarlo y verificarlo
            if resp1.get('otp_required'):
                transfer_id = resp1.get('transfer_id')

                # Generar código TOTP válido
                totp = pyotp.TOTP(settings.TOTP_SECRET)
                code = totp.now()
                registrar_log(payment_id, tipo_log="OTP_GENERATED", extra_info=code)

                # Verificación OTP
                resp2 = self.connector.send(
                    VERIFY_OTP_ENDPOINT,
                    json={'transfer_id': transfer_id, 'otp': code},
                    headers=headers
                )
                registrar_log(payment_id, tipo_log="TRANSFER_SUCCESS", extra_info=str(resp2))
                return JsonResponse(resp2)

            # 5) Si no requiere OTP, devolver resultado
            registrar_log(payment_id, tipo_log="TRANSFER_SUCCESS", extra_info=str(resp1))
            return JsonResponse(resp1)

        except Exception as e:
            registrar_log(payment_id, tipo_log="TRANSFER_ERROR", extra_info=str(e))
            return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
