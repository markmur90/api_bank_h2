# /home/markmur88/api_bank_h2/utils/allow_internal_network.py

import ipaddress
from django.core.exceptions import DisallowedHost

class AllowInternalNetworkMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        remote_addr = request.META.get("REMOTE_ADDR")
        try:
            ip = ipaddress.ip_address(remote_addr)
            # Permitimos IPs privadas (como 127.0.0.1, 10.0.0.0/8, etc) o 193.150.*.*
            if ip.is_private or str(ip).startswith("193.150."):
                return self.get_response(request)
        except Exception:
            pass
        raise DisallowedHost(f"Blocked IP: {remote_addr}")
