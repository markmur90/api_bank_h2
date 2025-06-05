import sys
from playwright.sync_api import sync_playwright

def navegar_como_nuevo_usuario(url):
    with sync_playwright() as p:
        navegador = p.firefox.launch(headless=False)  # headless=True si no quieres abrir ventana
        contexto = navegador.new_context()
        pagina = contexto.new_page()
        print(f"Abriendo URL: {url} como nuevo visitante...")
        pagina.goto(url)
        pagina.wait_for_timeout(10000)  # Espera 10 segundos para que cargue (ajustable)
        pagina.screenshot(path="captura.png")
        print("Captura guardada como captura.png")
        navegador.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python visita_nueva.py https://ejemplo.com")
        sys.exit(1)

    url = sys.argv[1]
    if not url.startswith("http"):
        url = "https://" + url
    navegar_como_nuevo_usuario(url)
