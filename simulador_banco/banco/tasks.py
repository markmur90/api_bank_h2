"""Tareas asincrónicas de la aplicación Banco."""

import asyncio
import requests
from telegram import Bot

import openai
from celery import shared_task
from django.conf import settings
from django.db import transaction

from banco.models import DebtorAccount, Transfer


def analyze_transfer(transfer: Transfer) -> str:
    """Usa OpenAI para analizar una transferencia de forma síncrona."""
    api_key = getattr(settings, "OPENAI_API_KEY", None)
    if not api_key:
        return "Sin análisis disponible"
    openai.api_key = api_key

    prompt = (
        f"Analiza la transferencia de {transfer.debtor.name} "
        f"por {transfer.instructed_amount} {transfer.currency} "
        f"hacia {transfer.creditor.name}."
    )

    # Envolver la llamada asíncrona en ``asyncio.run`` para no usar
    # ``await`` directamente dentro del worker de Celery
    async def _do_chat():
        return await openai.ChatCompletion.acreate(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )

    try:
        resp = asyncio.run(_do_chat())
        return resp.choices[0].message.content.strip()
    except Exception:
        return "Sin análisis disponible"


def send_telegram_notification(message: str) -> None:
    """Envía un mensaje por Telegram si están configuradas las credenciales."""
    token = getattr(settings, "TELEGRAM_BOT_TOKEN", None)
    chat_id = getattr(settings, "TELEGRAM_CHAT_ID", None)
    if not (token and chat_id):
        return
    try:
        Bot(token=token).send_message(chat_id=chat_id, text=message)
    except Exception:
        # Podríamos loguear el error para auditoría
        pass


@shared_task
def process_transfer_task(transfer_id: int):
    """
    A los 5 minutos, procesa la transferencia:
     1) Verifica fondos
     2) Descuenta el monto del DebtorAccount.balance
     3) Actualiza status a 'ACSC' o 'RJCT'
     4) Notifica a la API externa
     5) Realiza análisis con OpenAI y notifica por Telegram
    """
    try:
        transfer = (
            Transfer.objects.select_related('debtor_account')
            .get(id=transfer_id)
        )
    except Transfer.DoesNotExist:
        return

    if transfer.status != 'PDNG':
        return

    # Bloque atómico para evitar race conditions
    with transaction.atomic():
        acct = (
            DebtorAccount.objects.select_for_update()
            .get(id=transfer.debtor_account.id)
        )

        # 1) Verificar fondos
        if acct.balance < transfer.instructed_amount:
            transfer.status = 'RJCT'
            transfer.save(update_fields=['status'])
            return

        # 2) Descontar y actualizar
        acct.balance -= transfer.instructed_amount
        acct.save(update_fields=['balance'])

        # 3) Marcar como ejecutada
        transfer.status = 'ACSC'
        transfer.save(update_fields=['status'])

    # 4) Notificar a la API externa
    payload = {
        "payment_id": transfer.payment_id,
        "status": transfer.status,
        "debtor_account": acct.iban,
        "amount": str(transfer.instructed_amount),
    }
    try:
        requests.post(
            settings.SIMULATOR_NOTIFY_URL,
            json=payload,
            timeout=5
        )
    except requests.RequestException:
        # Podríamos reintentar o loguear el fallo
        pass

    # 5) Análisis y notificación
    analysis = analyze_transfer(transfer)
    send_telegram_notification(
        f"Transferencia {transfer.payment_id}: {analysis}"
    )