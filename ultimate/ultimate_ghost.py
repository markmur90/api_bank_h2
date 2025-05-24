# ghost_recon_ultimate_copy.py
import sys
import random
import time
import os
import re
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

def mostrar_ayuda():
    print("""
🕵️ Ghost Recon Ultimate - Navegación automática y manual por Tor

USO:

  🔁 Modo automático:
    ghost_recon_ultimate_copy.py <url> <identificadores> <repeticiones> <delay> <intento_id> [--tiempo=300]

  🧑‍💻 Modo manual:
    ghost_recon_ultimate_copy.py <url> <identificadores> <intento_id> --manual [--tiempo=5m]

  🛠️ Configuración de red:
    ghost_recon_ultimate_copy.py --setup-red=INTERFAZ



OPCIONES COMUNES:

  <url>                URL a visitar (ej: https://example.com)
  <identificadores>    Palabras clave a buscar (separadas por comas, ej: "login,email")
  <intento_id>         Identificador único del intento o sesión
  <repeticiones>       Nº de visitas automáticas
  <delay>              Espera (en segundos) entre repeticiones

  --manual             Activa modo interactivo con navegador
  --tiempo=X           Tiempo de navegación: segundos (ej: 300) o minutos (ej: 5m)
  --logdir=RUTA        Carpeta para guardar logs (default: logs/)
  --capturas=RUTA      Carpeta para guardar capturas (default: capturas/)
  --nombre=ID          Nombre base para logs y capturas (default: intento_id)
  --setup-red=INTERFAZ Configura firewall, cambia IP/MAC de INTERFAZ (ej: eth0)
  -h, --help           Muestra esta ayuda
  
  --tiempo=300        Tiempo de navegación en segundos o con 'm' para minutos (ej: --tiempo=5m)
  --logdir=RUTA       Carpeta para guardar logs (default: logs/)
  --capturas=RUTA     Carpeta para guardar capturas (default: capturas/)
  --nombre=ID         Nombre base del intento (en lugar de 'log_<intento_id>.txt')
  -h, --help          Muestra esta ayuda y termina
""")
    sys.exit(0)

def mostrar_ayuda_completa():
    print("""
═════════════════════════════════════════════════════════════
🕵️ GHOST RECON ULTIMATE - AYUDA Y EJEMPLOS DE USO
═════════════════════════════════════════════════════════════

Ghost Recon Ultimate permite navegar por URLs a través de Tor
detectando palabras clave, capturando evidencias y cambiando
tu identidad (IP/MAC) automáticamente.

─────────────────────────────────────────────────────────────
🔁 MODO AUTOMÁTICO
─────────────────────────────────────────────────────────────

Navegación desatendida en bucle, útil para hacer scraping,
detección de rastro o fingerprint.

USO:
  python3 ultimate_ghost.py <url> <identificadores> <repeticiones> <delay> <intento_id> [opciones]

EJEMPLO:
  python3 ultimate_ghost.py https://example.com login,password 5 10 intento_001

  ▪ Visita 5 veces la URL
  ▪ Busca "login" y "password"
  ▪ Espera 10 segundos entre visitas
  ▪ Guarda logs y capturas como intento_001_1, intento_001_2...

─────────────────────────────────────────────────────────────
🧑‍💻 MODO MANUAL
─────────────────────────────────────────────────────────────

Abre navegador visible para que el usuario navegue manualmente
y se rastrean identificadores mientras navegas.

USO:
  python3 ultimate_ghost.py <url> <identificadores> <intento_id> --manual [opciones]

EJEMPLO:
  python3 ultimate_ghost.py https://login.com email,clave sesion_007 --manual --tiempo=3m

  ▪ Abre navegador Firefox (Playwright) con Tor
  ▪ Monitorea rastro de palabras mientras navegas
  ▪ Guarda captura al cerrar y registra cookies

─────────────────────────────────────────────────────────────
🛠️ CONFIGURACIÓN DE RED
─────────────────────────────────────────────────────────────

Cambia la IP y MAC de tu interfaz de red, y configura UFW.

USO:
  python3 ultimate_ghost.py --setup-red=INTERFAZ

EJEMPLO:
  python3 ultimate_ghost.py --setup-red=eth0

  ▪ Reinicia UFW
  ▪ Cambia MAC aleatoriamente
  ▪ Solicita nueva IP con hostname aleatorio
  ▪ Guarda logs en logs/red y valores en cache/

─────────────────────────────────────────────────────────────
🧩 OPCIONES COMUNES (para todos los modos)
─────────────────────────────────────────────────────────────

  --tiempo=X           Tiempo de navegación (ej: --tiempo=5m o --tiempo=300)
  --logdir=RUTA        Carpeta donde guardar logs (default: logs/)
  --capturas=RUTA      Carpeta donde guardar capturas (default: capturas/)
  --nombre=ID          Nombre base para archivos (en lugar del intento_id)
  -h, --help           Muestra esta ayuda y termina

─────────────────────────────────────────────────────────────
📦 ARCHIVOS GENERADOS
─────────────────────────────────────────────────────────────

  ▪ logs/log_<nombre>.txt         ➜ Detalles de navegación y cookies
  ▪ capturas/captura_<nombre>.png ➜ Captura de pantalla del sitio
  ▪ logs/historial.txt            ➜ Registro centralizado de intentos
  ▪ logs/red/cambio_red_*.log     ➜ Resultado de setup de red
  ▪ cache/ip_actual.txt, mac_actual.txt ➜ Datos de identidad actual

─────────────────────────────────────────────────────────────
📲 ALERTAS EN TELEGRAM
─────────────────────────────────────────────────────────────

Cuando se detecta un rastro en el HTML, se envía un mensaje
automático al canal configurado.

Verifica que el TOKEN y CHAT_ID estén correctos en el script:

  TELEGRAM_TOKEN = "..."
  TELEGRAM_CHAT_ID = "..."

─────────────────────────────────────────────────────────────
📌 RECOMENDACIONES
─────────────────────────────────────────────────────────────

✔ Usa interfaces tipo `eth0`, `wlan0` para cambiar IP/MAC.
✔ Verifica que el servicio `Tor` esté activo en el puerto 9050.
✔ Ejecuta con permisos `sudo` cuando uses --setup-red.
✔ Guarda resultados para análisis forense o inteligencia OSINT.

═════════════════════════════════════════════════════════════
💀 Ghost Recon Ultimate v1.0 — by markmur88
═════════════════════════════════════════════════════════════
""")
    sys.exit(0)

def mostrar_ejemplos():
    print("""
═══════════════════════════════════════════════
📌 EJEMPLOS DE USO - GHOST RECON ULTIMATE
═══════════════════════════════════════════════

🔁 MODO AUTOMÁTICO:

  python3 ultimate_ghost.py https://example.com login,password 3 15 test_123
  → Visita 3 veces, espera 15s, busca "login" y "password", logs: test_123_1...

  python3 ultimate_ghost.py https://objetivo.net token,csrf 2 10 escaneo_01 --logdir=out/logs --capturas=out/caps --nombre=csrf_test

🧑‍💻 MODO MANUAL:

  python3 ultimate_ghost.py https://portal.com email,clave intentoZ --manual --tiempo=5m
  → Abre navegador visible, rastrea HTML durante 5 minutos.

  python3 ultimate_ghost.py https://darknet.site access,form sesion44 --manual --capturas=imgs/

🛠️ CAMBIO DE RED:

  python3 ultimate_ghost.py --setup-red=eth0
  → Reinicia UFW, cambia MAC/IP, guarda log en logs/red/

═══════════════════════════════════════════════
⏩ Usa -h o --help para ver ayuda completa
═══════════════════════════════════════════════
""")
    sys.exit(0)

def parsear_tiempo():
    tiempo = 60
    for arg in sys.argv:
        if arg.startswith("--tiempo="):
            valor = arg.split("=")[1].strip()
            if re.fullmatch(r"\d+m", valor):
                tiempo = int(valor[:-1]) * 60
            elif valor.isdigit():
                tiempo = int(valor)
            else:
                print("[!] Formato de tiempo inválido. Usa --tiempo=300 o --tiempo=5m")
                sys.exit(1)
    return tiempo

def extraer_parametro(nombre, por_defecto):
    for arg in sys.argv:
        if arg.startswith(f"--{nombre}="):
            return arg.split("=", 1)[1].strip()
    return por_defecto

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

def guardar_resultados(path_log, path_captura, agente, url, identificadores, reconocido, cookies, html):
    os.makedirs(os.path.dirname(path_log), exist_ok=True)
    os.makedirs(os.path.dirname(path_captura), exist_ok=True)

    # Guardar HTML completo en archivo separado
    html_path = path_log.replace("log_", "html_").replace(".txt", ".html")
    with open(html_path, "w", encoding="utf-8") as html_file:
        html_file.write(html)

    with open(path_log, "w", encoding="utf-8") as log:
        log.write(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        log.write(f"User-Agent: {agente}\n")
        log.write(f"URL: {url}\n")
        log.write(f"Identificadores buscados: {','.join(identificadores)}\n")
        log.write(f"Reconocido: {'SÍ' if reconocido else 'NO'}\n")
        log.write("Cookies:\n")
        for c in cookies:
            log.write(f"{c}\n")
        log.write(f"\n--- HTML parcial (ver completo en {os.path.basename(html_path)}) ---\n")
        log.write(html[:3000])

def modo_manual(url, identificadores, intento_id, tiempo_total, logdir, capturas, nombre_archivo):
    agente = random.choice(USER_AGENTS)
    log_path = os.path.join(logdir, f"log_{nombre_archivo}.txt")
    captura_path = os.path.join(capturas, f"captura_{nombre_archivo}.png")

    print("🚀 Lanzando navegador para navegación manual...")
    try:
        with sync_playwright() as p:
            browser = p.firefox.launch(proxy={"server": "socks5://127.0.0.1:9050"}, headless=False)
            context = browser.new_context(user_agent=agente)
            page = context.new_page()
            page.goto(url, timeout=30000)

            start = time.time()
            rastro_detectado = False

            while time.time() - start < tiempo_total:
                html = page.content()
                con_rastro = any(id.strip().lower() in html.lower() for id in identificadores)
                if con_rastro and not rastro_detectado:
                    enviar_alerta_telegram(f"👁️ Detectado en modo manual: {url} — intento: {intento_id}")
                    rastro_detectado = True
                time.sleep(15)

            page.screenshot(path=captura_path)
            cookies = context.cookies()

            guardar_resultados(log_path, captura_path, agente, url, identificadores, rastro_detectado, cookies, html)
            registrar_en_historial("manual", url, identificadores, intento_id, tiempo_total, logdir, capturas, nombre_archivo)
            browser.close()
            print("✅ Sesión finalizada. Log y captura guardados.")

    except Exception as e:
        print(f"[!] Error en modo manual: {e}")

def visitar_como_fantasma(url, identificadores, intento_id, tiempo_navegacion, logdir, capturas, nombre_archivo):
    agente = random.choice(USER_AGENTS)
    log_path = os.path.join(logdir, f"log_{nombre_archivo}.txt")
    captura_path = os.path.join(capturas, f"captura_{nombre_archivo}.png")

    try:
        with sync_playwright() as p:
            browser = p.firefox.launch(proxy={"server": "socks5://127.0.0.1:9050"})
            contexto = browser.new_context(user_agent=agente)
            pagina = contexto.new_page()
            pagina.goto(url, timeout=30000)

            print(f"🕵️‍♂️ Navegando {tiempo_navegacion} segundos...")
            time.sleep(tiempo_navegacion)

            html = pagina.content()
            pagina.screenshot(path=captura_path)
            cookies = contexto.cookies()
            con_rastro = any(id.strip().lower() in html.lower() for id in identificadores)

            guardar_resultados(log_path, captura_path, agente, url, identificadores, con_rastro, cookies, html)

            if con_rastro:
                mensaje = f"🕵️‍♂️ *Ghost Recon Alert*\nURL: {url}\nReconocido: SÍ\nIntento ID: {intento_id}"
                enviar_alerta_telegram(mensaje)

            browser.close()
            registrar_en_historial("automatico", url, identificadores, intento_id, tiempo_navegacion, logdir, capturas, nombre_archivo)


    except Exception as e:
        print(f"[!] Error durante navegación: {e}")

def registrar_en_historial(modo, url, identificadores, intento_id, tiempo, logdir, capturas, nombre_archivo):
    os.makedirs("logs", exist_ok=True)
    with open("logs/historial.txt", "a", encoding="utf-8") as h:
        h.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ")
        h.write(f"MODO={modo} URL={url} ID={intento_id} TIEMPO={tiempo}s ")
        h.write(f"IDENTIFICADORES={','.join(identificadores)} ")
        h.write(f"LOGDIR={logdir} CAPTURAS={capturas} ARCHIVO={nombre_archivo}\n")

def setup_red(interfaz):
    import subprocess
    from datetime import datetime

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"logs/red/cambio_red_{timestamp}.log"
    cache_dir = "cache"

    os.makedirs("logs/red", exist_ok=True)
    os.makedirs(cache_dir, exist_ok=True)

    def run(cmd, silent=False):
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if not silent:
            print(res.stdout.strip())
        return res.stdout.strip()

    print("🛡️ Configurando firewall UFW...")
    run("sudo ufw --force reset")
    run("sudo ufw default deny incoming")
    run("sudo ufw default allow outgoing")
    for puerto in [80, 443, 2222, 8000, 8001, 8011, 9050, 9051]:
        run(f"sudo ufw allow {puerto}/tcp")
    run("sudo ufw --force enable")
    print("✅ UFW configurado correctamente")

    print(f"🔁 Cambiando MAC de la interfaz {interfaz}")
    run(f"sudo ip link set {interfaz} up", silent=True)
    time.sleep(2)

    mac_antes = run(f"sudo macchanger -s {interfaz} | awk '/Current MAC:/ {{print $3}}'") or "No disponible"
    ip_antes = run(f"ip -4 addr show {interfaz} | awk '/inet / {{print $2}}' | cut -d/ -f1") or "No disponible"

    with open(f"{cache_dir}/mac_antes.txt", "w") as f: f.write(mac_antes + "\n")
    with open(f"{cache_dir}/ip_antes.txt", "w") as f: f.write(ip_antes + "\n")

    print("📤 Liberando IP actual...")
    run(f"sudo dhclient -r {interfaz}")
    run(f"sudo ip link set {interfaz} down")
    mac_nueva = run(f"sudo macchanger -r {interfaz} | awk '/New MAC:/ {{print $3}}'")
    run(f"sudo ip link set {interfaz} up")
    time.sleep(2)

    rand_host = "ghost-" + ''.join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=6))
    print(f"📥 Solicitando nueva IP con hostname aleatorio {rand_host}...")
    run(f"sudo HOSTNAME={rand_host} dhclient -v {interfaz}")
    time.sleep(5)

    ip_actual = run(f"ip -4 addr show {interfaz} | awk '/inet / {{print $2}}' | cut -d/ -f1") or "No disponible"

    if ip_actual == ip_antes:
        print("⚠ La IP no cambió. Reintentando...")
        run(f"sudo ip link set {interfaz} down")
        mac_nueva = run(f"sudo macchanger -r {interfaz} | awk '/New MAC:/ {{print $3}}'")
        run(f"sudo ip link set {interfaz} up")
        time.sleep(2)
        rand_host = "ghost-" + ''.join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=6))
        run(f"sudo HOSTNAME={rand_host} dhclient -v {interfaz}")
        time.sleep(5)
        ip_actual = run(f"ip -4 addr show {interfaz} | awk '/inet / {{print $2}}' | cut -d/ -f1") or "No disponible"

    with open(f"{cache_dir}/mac_actual.txt", "w") as f: f.write(mac_nueva + "\n")
    with open(f"{cache_dir}/ip_actual.txt", "w") as f: f.write(ip_actual + "\n")

    resumen = f"""
=========================================
🔁 Cambio de red realizado ({datetime.now().strftime('%Y-%m-%d %H:%M:%S')})
🖧 Interfaz: {interfaz}
🔍 MAC anterior: {mac_antes}
🎉 MAC actual:   {mac_nueva}
🌐 IP anterior:  {ip_antes}
🌐 IP actual:    {ip_actual}
=========================================
""".strip()

    with open(log_file, "w") as f: f.write(resumen + "\n")
    print(resumen)

def mostrar_version():
    print("""
Ghost Recon Ultimate v1.0.0
Autor: markmur88
Compilación: Mayo 2025

🔐 Herramienta avanzada de navegación anónima con Tor,
detección de rastros web y cambio de identidad de red.
""")
    sys.exit(0)

def main():
    if "--version" in sys.argv:
        mostrar_version()
    
    if "--ejemplos" in sys.argv:
        mostrar_ejemplos()
    
    if any(x in sys.argv for x in ["-h", "--help"]):
        mostrar_ayuda_completa()

    if any(a.startswith("--setup-red=") for a in sys.argv):
        interfaz = extraer_parametro("setup-red", None)
        setup_red(interfaz)

    tiempo = parsear_tiempo()
    logdir = extraer_parametro("logdir", "logs")
    capturas = extraer_parametro("capturas", "capturas")
    nombre = extraer_parametro("nombre", None)

    if "--manual" in sys.argv:
        try:
            url, ids, intento = sys.argv[1], sys.argv[2].split(","), sys.argv[3]
        except IndexError:
            print("[!] Argumentos insuficientes para modo manual.")
            mostrar_ayuda()

        if not verificar_tor():
            print("⛔ Tor no disponible. Abortando.")
            sys.exit(3)

        modo_manual(url, ids, intento, tiempo, logdir, capturas, nombre or intento)

    else:
        if len(sys.argv) < 6:
            print("[!] Argumentos insuficientes para modo automático.")
            mostrar_ayuda()

        url, ids, reps, delay, intento = sys.argv[1], sys.argv[2].split(","), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
        if not verificar_tor():
            print("⛔ Tor no disponible. Abortando.")
            sys.exit(3)

        for i in range(1, reps + 1):
            print(f"\n--- Intento #{i} ---")
            cambiar_ip_tor()
            nombre_i = f"{nombre or intento}_{i}"
            visitar_como_fantasma(url, ids, intento, tiempo, logdir, capturas, nombre_i)
            if i < reps:
                print(f"⏳ Esperando {delay} segundos...")
                time.sleep(delay)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[!] Ejecución interrumpida por el usuario.")
        sys.exit(130)
