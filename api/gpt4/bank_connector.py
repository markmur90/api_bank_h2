import socket
from urllib.parse import urljoin
from .http_client import HTTPClient
from .config_loader import ConfigLoader

class BankConnector:
    def __init__(self, cfg: ConfigLoader):
        self.cfg = cfg
        self._setup()

    def _setup(self):
        self.verify = self.cfg.get_bool('BANK_VERIFY_SSL', True)
        self.timeout = self.cfg.get_int('BANK_TIMEOUT', 10)
        self.retries = self.cfg.get_int('BANK_RETRIES', 3)
        self.mock_mode = self.cfg.get_bool('BANK_ALLOW_MOCK', False)
        self.bank_host = self.cfg.get_str('BANK_HOST', required=True)
        self.bank_port = self.cfg.get_int('BANK_PORT', 443)
        self.http = HTTPClient(self.verify, self.timeout, self.retries)

    def _is_secure_network(self) -> bool:
        prefix = self.cfg.get_str('BANK_NET_PREFIX')
        try:
            local_ip = socket.gethostbyname(socket.gethostname())
        except socket.error:
            return False
        return bool(prefix and local_ip.startswith(prefix))

    def _choose_base(self) -> str:
        if self._is_secure_network():
            ip = socket.gethostbyname(self.bank_host)
            return f"https://{ip}:{self.bank_port}"
        if self.mock_mode:
            return f"http://{self.bank_host}:{self.bank_port}"
        raise ConnectionError("No autorizado para conectar al banco")

    def send(self, path: str, method: str = 'POST', headers: dict = None, json_body: dict = None) -> dict:
        base = self._choose_base()
        url = urljoin(base, path)
        response = self.http.request(method, url, headers=headers or {}, json=json_body)
        return response.json()