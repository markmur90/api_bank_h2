# /home/markmur88/api_bank_h2/utils/allow_internal_network.py

import ipaddress
import logging
from django.core.exceptions import DisallowedHost

logger = logging.getLogger(__name__)

class AllowInternalNetworkMiddleware:
    """
    Middleware que sólo permite accesos desde redes internas (RFC1918) o localhost.
    Loggea cada intento bloqueado para facilitar trazabilidad.
    """
    def __init__(self, get_response):
        self.get_response = get_response
        # Definición de redes permitidas (todas en CIDR)
        self.allowed_networks = [
            ipaddress.ip_network("127.0.0.0/8"),      # localhost
            ipaddress.ip_network("10.0.0.0/8"),       # red privada A
            ipaddress.ip_network("172.16.0.0/12"),    # red privada B
            ipaddress.ip_network("193.150.0.0/16"),   # red privada C
        ]

    def __call__(self, request):
        raw_ip = request.META.get('REMOTE_ADDR', '')
        try:
            ip = ipaddress.ip_address(raw_ip)
        except ValueError:
            # IP malformada
            logger.warning(f"[AllowInternalNetwork] IP inválida recibida: {raw_ip}")
            raise DisallowedHost(f"Blocked IP (invalid): {raw_ip}")

        # Verificamos si está dentro de alguna de las redes permitidas
        if not any(ip in net for net in self.allowed_networks):
            logger.warning(f"[AllowInternalNetwork] Bloqueada IP externa: {ip}")
            raise DisallowedHost(f"Blocked IP: {ip}")

        return self.get_response(request)
