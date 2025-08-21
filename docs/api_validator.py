from decimal import Decimal
from typing import Dict, Optional, Tuple
from django.core.exceptions import ValidationError
from banco.models import Transfer, LogTransferencia

class APITransferValidator:
    """
    Validador para transferencias antes de enviarlas a una API externa.
    Realiza validaciones específicas para asegurar que la transferencia
    cumple con los requisitos de la API.
    """

    @staticmethod
    def validate_transfer_for_api(transfer: Transfer) -> Tuple[bool, Optional[str]]:
        """
        Valida una transferencia antes de enviarla a la API externa.
        
        Args:
            transfer: Objeto Transfer a validar
            
        Returns:
            Tuple[bool, Optional[str]]: (es_valido, mensaje_error)
        """
        try:
            # Validar estado de la transferencia
            if transfer.status not in ['PDNG', 'ACWP']:
                return False, f'Estado inválido para envío: {transfer.status}'

            # Validar que tenga los datos básicos necesarios
            if not all([
                transfer.payment_id,
                transfer.debtor,
                transfer.creditor,
                transfer.debtor_account,
                transfer.creditor_account,
                transfer.instructed_amount,
                transfer.currency
            ]):
                return False, 'Faltan datos básicos de la transferencia'

            # Validar datos del deudor
            if not all([
                transfer.debtor.name,
                transfer.debtor.address,
                transfer.debtor_account.iban
            ]):
                return False, 'Datos incompletos del deudor'

            # Validar datos del acreedor
            if not all([
                transfer.creditor.name,
                transfer.creditor.address,
                transfer.creditor_account.iban
            ]):
                return False, 'Datos incompletos del acreedor'

            # Validar monto
            if transfer.instructed_amount <= 0:
                return False, 'El monto debe ser mayor a 0'

            # Validar saldo suficiente
            if transfer.debtor_account.balance < transfer.instructed_amount:
                return False, 'Saldo insuficiente'

            # Validar moneda
            if transfer.currency not in ['EUR', 'USD']:
                return False, f'Moneda no soportada: {transfer.currency}'

            # Registrar log de validación exitosa
            LogTransferencia.objects.create(
                registro=transfer.payment_id,
                tipo_log='VALIDATION',
                contenido='Validación API exitosa'
            )

            return True, None

        except Exception as e:
            error_msg = f'Error en validación: {str(e)}'
            LogTransferencia.objects.create(
                registro=transfer.payment_id,
                tipo_log='ERROR',
                contenido=error_msg
            )
            return False, error_msg

    @staticmethod
    def format_transfer_for_api(transfer: Transfer) -> Dict:
        """
        Formatea los datos de la transferencia para enviarlos a la API externa.
        
        Args:
            transfer: Objeto Transfer a formatear
            
        Returns:
            Dict: Datos formateados para la API
        """
        return {
            'payment_id': transfer.payment_id,
            'debtor': {
                'name': transfer.debtor.name,
                'address': transfer.debtor.address,
                'account': {
                    'iban': transfer.debtor_account.iban,
                    'currency': transfer.currency
                }
            },
            'creditor': {
                'name': transfer.creditor.name,
                'address': transfer.creditor.address,
                'account': {
                    'iban': transfer.creditor_account.iban,
                    'currency': transfer.currency
                }
            },
            'transaction': {
                'amount': str(transfer.instructed_amount),
                'currency': transfer.currency,
                'purpose_code': transfer.purpose_code or 'GDSV',
                'remittance_info': transfer.remittance_information_unstructured
            }
        } 