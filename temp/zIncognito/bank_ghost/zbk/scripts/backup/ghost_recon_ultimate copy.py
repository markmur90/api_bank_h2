import sys
import random
import time
import os
import requests
import subprocess
from datetime import datetime
from playwright.sync_api import sync_playwright

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; rv:120.0) Gecko/20100101 Firefox/120.0",
]

TELEGRAM_TOKEN = "6983248274:AAGyNmK_IeXh-yN1PQsGDqmEaghhNqig6Js"
TELEGRAM_CHAT_ID = "769077177"

def cambiar_ip_tor():
    try:
        s = subprocess.Popen(
            ['torify', 'curl', '--socks5-hostname', '127.0.0.1:9050', '-s', 'https://check.torproject.org/'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        salida, _ = s.communicate()
        print("[*] IP Tor actual:\n", salida.decode().strip())
    except Exception as e:
        print(f"[!] Error al cambiar IP: {e}")

def enviar_alerta_telegram(mensaje):
    try:
        url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
        data = {"chat_id": TELEGRAM_CHAT_ID, "text": mensaje}
        requests.post(url, data=data)
        print("[*] Alerta enviada por Telegram.")
    except Exception as e:
        print(f"[!] Error enviando alerta: {e}")

def visitar_como_fantasma(url, identificadores, intento_id, tiempo_navegacion=60):
    agente = random.choice(USER_AGENTS)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    nombre_log = f"logs/log_{intento_id}.txt"
    nombre_captura = f"capturas/captura_{intento_id}.png"

    os.makedirs("logs", exist_ok=True)
    os.makedirs("capturas", exist_ok=True)

    try:
        with sync_playwright() as p:
            browser = p.firefox.launch(proxy={"server": "socks5://127.0.0.1:9050"})
            contexto = browser.new_context(user_agent=agente)
            pagina = contexto.new_page()
            pagina.goto(url, timeout=30000)

            print(f"🕵️‍♂️ Navegando {tiempo_navegacion} segundos...")
            time.sleep(tiempo_navegacion)

            html = pagina.content()
            pagina.screenshot(path=nombre_captura)
            cookies = contexto.cookies()
            con_rastro = any(id.strip().lower() in html.lower() for id in identificadores)

            with open(nombre_log, "w", encoding="utf-8") as log:
                log.write(f"Fecha: {timestamp}\n")
                log.write(f"User-Agent: {agente}\n")
                log.write(f"URL: {url}\n")
                log.write(f"Identificadores buscados: {','.join(identificadores)}\n")
                log.write(f"Reconocido: {'SÍ' if con_rastro else 'NO'}\n")
                log.write("Cookies:\n")
                for c in cookies:
                    log.write(f"{c}\n")
                log.write("\n--- HTML Recortado ---\n")
                log.write(html[:3000])

            if con_rastro:
                mensaje = f"🕵️‍♂️ *Ghost Recon Alert*\nURL: {url}\nReconocido: SÍ\nIntento ID: {intento_id}"
                enviar_alerta_telegram(mensaje)

            browser.close()
            return con_rastro

    except Exception as e:
        print(f"[!] Error durante navegación: {e}")
        return False

def modo_ghost_recon(url, identificadores, repeticiones=1, delay=30):
    rastro_detectado = False
    for i in range(1, repeticiones + 1):
        print(f"\n--- Intento #{i} ---")
        cambiar_ip_tor()
        resultado = visitar_como_fantasma(url, identificadores, f"batch_{i}")
        if resultado:
            rastro_detectado = True
        if i < repeticiones:
            print(f"Esperando {delay} segundos...")
            time.sleep(delay)
    if rastro_detectado:
        sys.exit(100)

def verificar_tor():
    print("[*] Verificando conexión a través de Tor...")
    try:
        proxies = {
            "http": "socks5h://127.0.0.1:9050",
            "https": "socks5h://127.0.0.1:9050"
        }
        res = requests.get("https://check.torproject.org/", proxies=proxies, timeout=10000)
        
        if "Congratulations. This browser is configured to use Tor" in res.text:
            print("✅ Conectado correctamente a través de Tor.")
            return True
        else:
            print("❌ La conexión NO está pasando por Tor.")
            return False
    except Exception as e:
        print(f"❌ Error al verificar Tor: {e}")
        return False
    
    
if __name__ == "__main__":
    if len(sys.argv) < 6:
        print("Uso: ghost_recon_ultimate.py <url> <identificadores> <repeticiones> <delay> <intento_id> [--tiempo=segundos]")
        sys.exit(1)

    url = sys.argv[1]
    identificadores = [id.strip() for id in sys.argv[2].split(",") if id.strip()]
    if not identificadores:
        print("[!] No se especificaron identificadores válidos.")
        sys.exit(2)

    repeticiones = int(sys.argv[3])
    delay = int(sys.argv[4])
    intento_id = sys.argv[5]

    # Determinar tiempo de navegación
    tiempo = 60
    for arg in sys.argv:
        if arg.startswith('--tiempo='):
            try:
                tiempo = int(arg.split('=')[1])
            except:
                pass

    # Verificación única de Tor antes de todo
    if not verificar_tor():
        print("⛔ Tor no disponible. Registrando intento fallido.")
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_path = f"logs/log_{intento_id}.txt"

        os.makedirs("logs", exist_ok=True)
        with open(log_path, "w", encoding="utf-8") as log:
            log.write(f"Fecha: {timestamp}\n")
            log.write(f"User-Agent: NO_USER_AGENT\n")
            log.write(f"URL: {url}\n")
            log.write(f"Identificadores buscados: {','.join(identificadores)}\n")
            log.write(f"Tiempo de navegación (fallido): {tiempo}s\n")
            log.write(f"Reconocido: NO\n")
            log.write("Error: Conexión fallida - Tor no disponible.\n")

        sys.exit(3)

    # Ejecutar repeticiones
    for _ in range(repeticiones):
        visitar_como_fantasma(url, identificadores, intento_id, tiempo_navegacion=tiempo)
        time.sleep(delay)