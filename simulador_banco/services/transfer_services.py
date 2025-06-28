import datetime
from typing import Any, Dict
from django.db import transaction
from django.utils import timezone
from django.core.exceptions import ValidationError
from banco.models import Transfer, DebtorAccount
from banco.tasks import process_transfer_task


class TransferService:
    """
    Servicio para ingestar y procesar Transfers respetando:
     - idempotencia por payment_id
     - rate-limit (5 en 5 minutos)
     - procesamiento diferido a los 5 minutos
    """

    RATE_LIMIT = 5
    WINDOW_MINUTES = 5

    @staticmethod
    @transaction.atomic
    def ingest_transfer(data: Dict[str, Any]) -> Transfer:
        """
        Inserta o rechaza una transferencia según reglas:
        data = {
          "payment_id": "...",
          "debtor_account_id": 1,
          "instructed_amount": "100.00",
          ... otros campos necesarios ...
        }
        """

        # 1) Idempotencia
        existing = Transfer.objects.filter(payment_id=data["Idempotency-Id"]).first()
        if existing:
            return existing

        # 2) Rate-limit: contar en ventana de 5 minutos
        window_start = timezone.now() - datetime.timedelta(
            minutes=TransferService.WINDOW_MINUTES
        )
        recent_count = Transfer.objects.filter(
            debtor_account_id=data["debtor_account_id"],
            created_at__gte=window_start
        ).count()
        if recent_count >= TransferService.RATE_LIMIT:
            # Creamos igual para registro, pero con status ‘RJCT’
            transfer = Transfer.objects.create(
                status='RJCT',
                **data
            )
            return transfer

        # 3) Creamos en estado Pendiente (‘PDNG’)
        data["status"] = 'PDNG'
        transfer = Transfer.objects.create(**data)

        # 4) Programamos el procesamiento 5 minutos después
        # Ignoramos chequeos de tipo para apply_async y acceso a id
        process_transfer_task.apply_async(  # type: ignore[attr-defined]
            args=[transfer.id],  # type: ignore[attr-defined]
            countdown=TransferService.WINDOW_MINUTES * 60
        )

        return transfer
