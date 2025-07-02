# api/gpt4_conexion/config.py
import os
from pathlib import Path
from pydantic import BaseSettings, Field
from dotenv import load_dotenv

# Cargar variables de entorno desde .env.local en el directorio raíz del proyecto
dotenv_path = Path(__file__).resolve().parent.parent.parent / '.env.local'
load_dotenv(dotenv_path)

class Settings(BaseSettings):
    DJANGO_ENV: str = Field(..., description="Entorno de ejecución: development|staging|production")
    SECRET_KEY: str = Field(..., env="SECRET_KEY")
    BANK_HOST: str = Field(..., env="BANK_HOST")
    BANK_PORT: int = Field(..., env="BANK_PORT")
    BANK_VERIFY_SSL: bool = Field(True, env="BANK_VERIFY_SSL")
    BANK_TIMEOUT: int = Field(10, env="BANK_TIMEOUT")
    BANK_RETRIES: int = Field(3, env="BANK_RETRIES")
    RED_SEGURA_PREFIX: str = Field(..., description="Prefijo de red segura (CIDR)", env="RED_SEGURA_PREFIX")
    BANK_ALLOW_MOCK: bool = Field(False, env="BANK_ALLOW_MOCK")
    SIMULADOR_SECRET_KEY: str = Field(..., env="SIMULADOR_SECRET_KEY")
    TOTP_SECRET: str = Field(..., env="TOTP_SECRET")
    SCOPE: str = Field(..., env="SCOPE")
    TIMEOUT: int = Field(..., env="TIMEOUT")

    class Config:
        env_file = dotenv_path
        env_file_encoding = 'utf-8'

settings = Settings()