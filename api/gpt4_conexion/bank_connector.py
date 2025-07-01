# heroku/api/gpt4_conexion/bank_connector.py
import logging
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from .config import settings

logger = logging.getLogger(__name__)

class BankConnector:
    def __init__(self):
        self.session = self._init_session()
        # Base URL dinámico según configuración
        self.base_url = f"{'https' if settings.BANK_VERIFY_SSL else 'http'}://{settings.BANK_HOST}:{settings.BANK_PORT}"

    def _init_session(self):
        session = requests.Session()
        retries = Retry(
            total=settings.BANK_RETRIES,
            backoff_factor=getattr(settings, 'BANK_BACKOFF_FACTOR', 0.3),
            status_forcelist=getattr(settings, 'BANK_RETRY_STATUS_FORCELIST', [502, 503, 504])
        )
        adapter = HTTPAdapter(max_retries=retries)
        session.mount('https://', adapter)
        session.mount('http://', adapter)
        session.verify = settings.BANK_VERIFY_SSL
        return session

    def send(self, endpoint: str, json: dict, headers: dict = None) -> dict:
        url = f"{self.base_url}{endpoint}"
        try:
            response = self.session.post(
                url,
                json=json,
                headers=headers or {},
                timeout=settings.BANK_TIMEOUT
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"BankConnector error calling {url}: {e}")
            raise
