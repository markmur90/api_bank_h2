#!/usr/bin/env bash
set -e

clear

confirmar() {
    echo ""
    printf "\033[1;34m¿Deseas ejecutar: %s? (s/n):\033[0m " "$1"
    read -r resp
    [[ "$resp" == "s" || -z "$resp" ]]
}

for PUERTO in 2222 8000 5000; do
    if lsof -i tcp:"$PUERTO" &>/dev/null; then
        if confirmar "Cerrar procesos en puerto $PUERTO"; then
            sudo fuser -k "${PUERTO}"/tcp || true
            echo -e "\033[1;32mPuerto $PUERTO liberado.\033[0m"
        fi
    fi
done

if confirmar "Detener contenedores Docker activos"; then
    PIDS=$(docker ps -q)
    if [ -n "$PIDS" ]; then
        sudo docker stop $PIDS
        echo -e "\033[1;32mContenedores Docker activos detenidos.\033[0m"
    else
        echo -e "\033[1;33mNo hay contenedores Docker activos.\033[0m"
    fi
    ALL_CONTAINERS=$(docker ps -a -q)
    if [ -n "$ALL_CONTAINERS" ]; then
        sudo docker rm $ALL_CONTAINERS
        echo -e "\033[1;32mTodos los contenedores eliminados.\033[0m"
    else
        echo -e "\033[1;33mNo hay contenedores para eliminar.\033[0m"
    fi
    ALL_IMAGES=$(docker images -q)
    if [ -n "$ALL_IMAGES" ]; then
        sudo docker rmi $ALL_IMAGES
        echo -e "\033[1;32mTodas las imágenes Docker eliminadas.\033[0m"
    else
        echo -e "\033[1;33mNo hay imágenes Docker para eliminar.\033[0m"
    fi
fi

echo "[+] Instalando dependencias del sistema..."
apt-get update
apt-get install -y ca-certificates curl gnupg python3 python3-pip

echo "[+] Configurando repositorio de Docker para Debian bookworm (base de Kali)..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[+] Añadiendo usuario al grupo docker..."
if [ -n "$SUDO_USER" ]; then USER_TO_ADD=$SUDO_USER; else USER_TO_ADD=$USER; fi
usermod -aG docker "$USER_TO_ADD"

echo "[+] Preparando estructura del honeypot..."
mkdir -p /opt/honeypot/{cfg,data,json,web/templates}

echo "[+] Generando configuración de Cowrie..."
cat << 'EOF' > /opt/honeypot/cfg/cowrie.cfg
[ssh]
listen_addr = 0.0.0.0
listen_port = 2222
hostname = srv-dns

[output_json]
enabled = true
path = /cowrie/data/json

[userdb]
authorized = admin:5f4dcc3b5aa765d61d8327deb882cf99,guest:084e0343a0486ff05530df6c705c8bb4

[commands]
enabled = true
extensions = ls,cat,uname,whoami,pwd,ps,ifconfig

[honeypot]
id = honeypot-vulntrap
loglevel = INFO
EOF

echo "[+] Generando visor web Flask..."
cat << 'EOF' > /opt/honeypot/web/app.py
from flask import Flask, render_template, jsonify
from pathlib import Path
import json

app = Flask(__name__)
LOGFILE = Path("/cowrie/data/json/cowrie.json")

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/events")
def events():
    if not LOGFILE.exists():
        return jsonify([])
    lines = LOGFILE.read_text(encoding="utf-8", errors="ignore").splitlines()
    last = lines[-100:] if len(lines) > 100 else lines
    entries = []
    for line in last:
        try:
            data = json.loads(line)
            entries.append({
                "timestamp": data.get("timestamp", ""),
                "src_ip": data.get("src_ip", ""),
                "username": data.get("username", ""),
                "password": data.get("password", ""),
                "input": data.get("input", ""),
                "eventid": data.get("eventid", ""),
            })
        except:
            continue
    return jsonify(entries[::-1])
EOF

cat << 'EOF' > /opt/honeypot/web/templates/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Cowrie Honeypot Feed</title>
    <meta http-equiv="refresh" content="10">
    <style>
        body { background: #111; color: #0f0; font-family: monospace; padding: 1rem; }
        .entry { margin-bottom: 1em; }
        .ip { color: #ff0; }
        .cmd { color: #0ff; }
    </style>
</head>
<body>
    <h1>Cowrie Honeypot Feed</h1>
    <div id="log"></div>
    <script>
        async function load() {
            const res = await fetch("/events");
            const data = await res.json();
            const log = document.getElementById("log");
            log.innerHTML = "";
            data.forEach(e => {
                const el = document.createElement("div");
                el.className = "entry";
                el.innerHTML = `[${e.timestamp}] <span class="ip">${e.src_ip}</span> - ${e.username}:${e.password} => <span class="cmd">${e.input || e.eventid}</span>`;
                log.appendChild(el);
            });
        }
        load();
        setInterval(load, 10000);
    </script>
</body>
</html>
EOF

echo "[+] Creando Dockerfile para visor web..."
cat << 'EOF' > /opt/honeypot/web/Dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN pip install flask
COPY app.py ./
COPY templates/ ./templates/
CMD ["flask", "run", "--host=0.0.0.0"]
EOF

echo "[+] Generando script de bloqueo automático por IP..."
cat << 'EOF' > /opt/honeypot/web/blocker.py
import json
import time
from pathlib import Path
from subprocess import run

SEEN = set()
LOGFILE = Path("/cowrie/data/json/cowrie.json")

while True:
    if not LOGFILE.exists():
        time.sleep(5)
        continue

    with LOGFILE.open("r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()[-200:]

    for line in lines:
        try:
            data = json.loads(line)
            ip = data.get("src_ip")
            if ip and ip not in SEEN:
                print(f"[BLOCK] {ip}")
                run(["iptables", "-I", "INPUT", "-s", ip, "-j", "DROP"])
                SEEN.add(ip)
        except:
            continue
    time.sleep(10)
EOF

echo "[+] Generando docker-compose principal..."
cat << 'EOF' > /opt/honeypot/docker-compose.yml
services:
  cowrie:
    image: cowrie/cowrie:latest
    container_name: cowrie
    restart: unless-stopped
    ports:
      - "2222:2222"
    volumes:
      - "./data:/cowrie/data"
      - "./cfg/cowrie.cfg:/cowrie/etc/cowrie.cfg"
    networks:
      - honeynet

  web:
    build:
      context: ./web
    container_name: cowrie-web
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - "./data:/cowrie/data"
    networks:
      - honeynet

networks:
  honeynet:
    driver: bridge
    internal: true
EOF

echo "[+] Iniciando sistema..."
cd /opt/honeypot
docker compose up -d --build

echo "[+] Honeypot desplegado."
echo "[+] Accede al visor en: http://0.0.0.0:5000"
echo "[+] Puedes iniciar el bloqueador con: docker exec -it cowrie-web python3 /app/blocker.py"
