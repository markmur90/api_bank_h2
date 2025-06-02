import sys
import random
from playwright.sync_api import sync_playwright


# 3. Uso desde terminal
#
#     Modo normal con ventana del navegador:
#       python visita_anonima.py https://www.tubanco.com
#
#     Modo oculto (sin mostrar ventana):
#       python visita_anonima.py https://www.tubanco.com --headless
#
#     Modo oculto + proxy Tor:
#       python visita_anonima.py https://www.tubanco.com --headless --proxy


USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; rv:120.0) Gecko/20100101 Firefox/120.0",
]

def navegar_como_nuevo_usuario(url, headless=True, usar_proxy=False):
    agente = random.choice(USER_AGENTS)
    opciones_proxy = {"server": "socks5://127.0.0.1:9050"} if usar_proxy else None

    with sync_playwright() as p:
        navegador = p.firefox.launch(headless=headless, proxy=opciones_proxy)
        contexto = navegador.new_context(user_agent=agente)
        pagina = contexto.new_page()
        print(f"\n[+] Visitando: {url}")
        print(f"[+] User-Agent aleatorio: {agente}")
        if usar_proxy:
            print("[+] Usando proxy (por ejemplo Tor en socks5://127.0.0.1:9050)")
        pagina.goto(url)
        pagina.wait_for_timeout(10000)
        pagina.screenshot(path="captura.png")
        print("[+] Captura guardada como captura.png")
        navegador.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python visita_anonima.py <url> [--headless] [--proxy]")
        sys.exit(1)

    url = sys.argv[1]
    if not url.startswith("http"):
        url = "https://" + url

    headless = "--headless" in sys.argv
    usar_proxy = "--proxy" in sys.argv

    navegar_como_nuevo_usuario(url, headless=headless, usar_proxy=usar_proxy)


