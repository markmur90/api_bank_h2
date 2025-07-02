 # api/gpt4_conexion/config.py
import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings
from pydantic import Field, Extra
from pydantic_settings import SettingsConfigDict

# Carga variables de entorno…
dotenv_path = Path(__file__).resolve().parent.parent.parent / '.env.local'
load_dotenv(dotenv_path)

class Settings(BaseSettings):
    DJANGO_ENV: str = Field(..., description="Entorno de ejecución: development|staging|production")
    SECRET_KEY: str = Field(..., env="SECRET_KEY")
    BANK_HOST: str = Field(..., env="BANK_HOST")
    BANK_PORT: int = Field(..., env="BANK_PORT")
    BANK_VERIFY_SSL: bool = Field(True, env="BANK_VERIFY_SSL")
    RED_SEGURA_PREFIX: str = Field(..., env="RED_SEGURA_PREFIX")
    BANK_ALLOW_MOCK: bool = Field(False, env="BANK_ALLOW_MOCK")
    SIMULADOR_SECRET_KEY: str = Field(..., env="SIMULADOR_SECRET_KEY")
    TOTP_SECRET: str = Field(..., env="TOTP_SECRET")
    BANK_TIMEOUT: int = Field(10, env="BANK_TIMEOUT")
    BANK_RETRIES: int = Field(3, env="BANK_RETRIES")

    # ← Indica que ignore variables de entorno extras
    model_config = SettingsConfigDict(
        env_file=str(dotenv_path),
        env_file_encoding='utf-8',
        extra='ignore',
    )

settings = Settings()


# Endpoints construidos dinámicamente
TRANSFER_ENDPOINT = f"http://{settings.BANK_HOST}:{settings.BANK_PORT}/api/transferencia/"
VERIFY_OTP_ENDPOINT = f"http://{settings.BANK_HOST}:{settings.BANK_PORT}/api/transferencia/verify/"
