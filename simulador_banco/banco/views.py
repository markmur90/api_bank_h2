from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

@csrf_exempt
def recibir_transferencia(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            required_fields = ["paymentIdentification", "debtor", "creditor", "instructedAmount"]
            if not all(field in data for field in required_fields):
                return JsonResponse({"estado": "RJCT", "mensaje": "Campos faltantes"}, status=400)
            return JsonResponse({"estado": "ACSC", "mensaje": "Transferencia aceptada"}, status=200)
        except Exception as e:
            return JsonResponse({"estado": "ERRO", "mensaje": str(e)}, status=500)
    return JsonResponse({"mensaje": "Solo POST permitido"}, status=405)
