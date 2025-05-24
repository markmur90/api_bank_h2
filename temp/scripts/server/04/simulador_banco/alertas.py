import smtplib
from email.message import EmailMessage
from config import ALERTA_CORREO

def enviar_alerta(asunto, mensaje):
    msg = EmailMessage()
    msg.set_content(mensaje)
    msg["Subject"] = asunto
    msg["From"] = "sistema@banco.com"
    msg["To"] = ALERTA_CORREO
    try:
        with smtplib.SMTP("localhost") as server:
            server.send_message(msg)
    except Exception as e:
        print(f"No se pudo enviar correo: {e}")
