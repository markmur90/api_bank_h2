# services/creditor_service.py

from django.db import transaction, IntegrityError
from django.core.exceptions import ValidationError
from banco.models import (
    PostalAddress, Creditor, CreditorAccount,
    iban_validator, country_validator
)

class CreditorService:
    """
    Servicio para procesar datos entrantes de Creditor.
    """

    @staticmethod
    @transaction.atomic
    def upsert_creditor(data: dict) -> Creditor:
        """
        Inserta o actualiza un Creditor y su cuenta IBAN.
        
        data = {
            "name": "ACME Corp",
            "address": {
                "country": "DE", "street": "Musterstr. 1", "city": "Berlin"
            },
            "account": {
                "iban": "DE44500105175407324931", "currency": "EUR"
            }
        }
        """
        # 1) Validar entrada básica
        country_validator(data["address"]["country"])
        iban_validator(data["account"]["iban"])

        # 2) Crear o actualizar PostalAddress
        addr_vals = data["address"]
        address, _ = PostalAddress.objects.update_or_create(
            country=addr_vals["country"],
            street=addr_vals["street"],
            city=addr_vals["city"],
            defaults=addr_vals
        )

        # 3) Crear o actualizar Creditor
        creditor_vals = {
            "name": data["name"],
            "address": address
        }
        creditor, created = Creditor.objects.update_or_create(
            name=data["name"],
            defaults=creditor_vals
        )

        # 4) Insertar o actualizar su cuenta
        acct_vals = data["account"]
        try:
            CreditorAccount.objects.update_or_create(
                creditor=creditor,
                iban=acct_vals["iban"],
                defaults={"currency": acct_vals.get("currency", "EUR")}
            )
        except IntegrityError as e:
            # Podría ocurrir si otro creditor ya cifró ese IBAN
            raise ValidationError({"iban": "IBAN duplicado o conflicto en base de datos."})

        return creditor
