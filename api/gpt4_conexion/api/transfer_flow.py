# api/gpt4_conexion/api/transfer_flow.py
import json
import os

from django.views import View
from django.http import JsonResponse, HttpRequest
from django.conf import settings
import pyotp

from api.gpt4_conexion.config import TRANSFER_ENDPOINT, VERIFY_OTP_ENDPOINT
from api.gpt4_conexion.bank_connector import BankConnector
from api.gpt4.utils import generar_xml_pain001, registrar_log
from api.utils.jwt_simulador import generar_token_simulador

class TransferView(View):
    connector = BankConnector()

    def post(self, request: HttpRequest):
        try:
            # 1) Parsear cuerpo JSON
            data = json.loads(request.body)
            payment_id = data.get('payment_id')
            xml = generar_xml_pain001(data)
            registrar_log(payment_id, tipo_log="TRANSFER_INIT")

            # 2) Generar JWT para el simulador (usuario admin)
            user = os.getenv('BANK_USER')
            token = generar_token_simulador(user)
            headers = {
                'Authorization': f'Bearer {token}',
                'Content-Type': 'application/json'
            }

            # 3) Solicitud inicial de transferencia
            resp1 = self.connector.send(
                TRANSFER_ENDPOINT,
                json={'xml': xml},
                headers=headers
            )
            registrar_log(payment_id, tipo_log="TRANSFER_REQUESTED", extra_info=str(resp1))

            # 4) Si se requiere OTP/TOTP, generarlo y verificarlo
            if resp1.get('otp_required') or resp1.get('requires_otp'):
                transfer_id = resp1.get('transfer_id')
                totp = pyotp.TOTP(settings.TOTP_SECRET)
                otp_code = totp.now()
                registrar_log(payment_id, tipo_log="OTP_GENERATED", extra_info=otp_code)

                resp2 = self.connector.send(
                    VERIFY_OTP_ENDPOINT,
                    json={'transfer_id': transfer_id, 'otp': otp_code},
                    headers=headers
                )
                registrar_log(payment_id, tipo_log="TRANSFER_SUCCESS", extra_info=str(resp2))
                return JsonResponse(resp2, status=200)

            # 5) Si no requiere OTP, devolver resultado directamente
            registrar_log(payment_id, tipo_log="TRANSFER_SUCCESS", extra_info=str(resp1))
            return JsonResponse(resp1, status=200)

        except Exception as e:
            registrar_log(None, tipo_log="TRANSFER_ERROR", extra_info=str(e))
            return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
