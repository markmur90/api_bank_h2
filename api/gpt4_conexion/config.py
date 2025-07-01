# config.py
import os
from pydantic import BaseSettings, Field
from dotenv import load_dotenv
from pathlib import Path
# Siempre cargamos el .env raíz para desarrollo local
load_dotenv(Path(__file__).resolve().parent.parent.parent / '.env.local')


class Settings(BaseSettings):
    DJANGO_ENV: str = Field(..., description="Entorno de ejecución: local|staging|production")
    SECRET_KEY: str
    BANK_HOST: str
    BANK_PORT: int
    BANK_VERIFY_SSL: bool = True
    BANK_TIMEOUT: int = 10
    BANK_RETRIES: int = 3
    RED_SEGURA_PREFIX: str = Field(..., description="Prefijo de red segura (CIDR)")

    class Config:
        env_file = env_file
        env_file_encoding = 'utf-8'

settings = Settings()