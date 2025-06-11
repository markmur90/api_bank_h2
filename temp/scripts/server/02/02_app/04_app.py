import os, time, threading, socket, subprocess, csv, nmap, requests, webbrowser, datetime, json
from datetime import datetime as dt
from dotenv import load_dotenv
load_dotenv()
from flask import (
    Flask, render_template_string, request, redirect, url_for,
    session, send_from_directory, Response
)
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, IPAddress
from functools import wraps

HONEYPOT_IP = "0.0.0.0"
HONEYPOT_PORTS = [2222, 8000]
REAL_BACKEND = "127.0.0.1"
LOG_FILE = "honeypot_logs.csv"
REPORT_DIR = "reports"
BANNER = b"SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2\r\n"

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')
os.makedirs(REPORT_DIR, exist_ok=True)
log_lock = threading.Lock()

def init_log_file():
    if os.path.exists(LOG_FILE):
        os.remove(LOG_FILE)
    with open(LOG_FILE, 'w', newline='') as f:
        csv.writer(f).writerow(["timestamp","ip","port","protocol","info"])

def log_attempt(ip, port, protocol, info):
    timestamp = dt.now().isoformat()
    with log_lock, open(LOG_FILE, 'a', newline='') as f:
        csv.writer(f).writerow([timestamp, ip, port, protocol, info])

def handle_client(client, address, port):
    if port == 2222:
        try:
            client.sendall(BANNER)
            data = client.recv(1024)
            if data:
                log_attempt(address[0], port, "SSH", data.decode(errors='ignore').strip())
        finally:
            client.close()
    elif port == 8000:
        remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            remote.connect((REAL_BACKEND, GUNICORN_PORT))
            req = client.recv(4096)
            if req:
                first_line = req.decode(errors='ignore').splitlines()[0]
                log_attempt(address[0], port, "HTTP", first_line)
                remote.sendall(req)
                remote.shutdown(socket.SHUT_WR)
                while True:
                    chunk = remote.recv(4096)
                    if not chunk:
                        break
                    client.sendall(chunk)
        except:
            pass
        finally:
            client.close()
            remote.close()

def start_honeypot(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HONEYPOT_IP, port))
    s.listen(1000)
    while True:
        client, addr = s.accept()
        threading.Thread(target=handle_client, args=(client, addr, port), daemon=True).start()

def free_port(port):
    subprocess.run(f"lsof -ti:{port} | xargs -r kill -9", shell=True)

def find_free_port(start=5000, end=5100):
    for p in range(start, end):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(('0.0.0.0', p))
                return p
            except OSError:
                continue
    raise RuntimeError("No free ports found")

class LoginForm(FlaskForm):
    username = StringField('Usuario', validators=[DataRequired()])
    password = PasswordField('Contraseña', validators=[DataRequired()])
    submit = SubmitField('Ingresar')

class ScanForm(FlaskForm):
    ip = StringField('Dirección IP', validators=[DataRequired(), IPAddress()])
    submit = SubmitField('Escanear')

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('logged'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

login_template = """<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Login</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head><body class="d-flex align-items-center justify-content-center vh-100">
<form method="post" class="p-4 border rounded bg-light">
  {{ form.hidden_tag() }}
  <div class="mb-3">{{ form.username.label }}{{ form.username(class_='form-control') }}</div>
  <div class="mb-3">{{ form.password.label }}{{ form.password(class_='form-control') }}</div>
  <div>{{ form.submit(class_='btn btn-primary w-100') }}</div>
</form></body></html>"""

scan_template = """<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Escanear & Honeypot</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head><body class="p-4">
  <div class="d-flex justify-content-between mb-4">
    <h1>Scanner</h1>
    <a href="{{ url_for('logout') }}" class="btn btn-danger">Cerrar sesión</a>
  </div>
  <div class="card mb-4">
    <div class="card-body">
      <form id="scan-form" class="mb-3">
        <div class="input-group">
          <input id="ip-input" name="ip" class="form-control" placeholder="127.0.0.1">
          <button class="btn btn-primary">Escanear</button>
        </div>
      </form>
      <div class="modal fade" id="progressModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg"><div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Progreso de escaneo</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body" id="progress-body" style="height:300px;overflow:auto;"></div>
          <div class="modal-footer">
            <button class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
          </div>
        </div></div>
      </div>
    </div>
  </div>
  <div class="card">
    <div class="card-body">
      <h2>Honeypot Logs</h2>
      <table class="table table-striped">
        <thead><tr><th>Fecha</th><th>IP</th><th>Puerto</th><th>Protocolo</th><th>Info</th></tr></thead>
        <tbody id="logs-body">
        {% for l in logs %}
          <tr>
            <td>{{ l.timestamp }}</td><td>{{ l.ip }}</td><td>{{ l.port }}</td>
            <td>{{ l.protocol }}</td><td>{{ l.info }}</td>
          </tr>
        {% endfor %}
        </tbody>
      </table>
    </div>
  </div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
const form = document.getElementById('scan-form'),
      ipInput = document.getElementById('ip-input'),
      modal = new bootstrap.Modal(document.getElementById('progressModal')),
      body  = document.getElementById('progress-body');

form.addEventListener('submit', e => {
  e.preventDefault();
  body.innerHTML = '';
  modal.show();
  const es = new EventSource("{{ stream_url }}?ip=" + encodeURIComponent(ipInput.value));
  es.onmessage = e => {
    if (e.data === 'DONE') {
      es.close();
      modal.hide();
      setTimeout(()=>window.location.reload(), 500);
    } else {
      const p = document.createElement('p');
      p.textContent = e.data;
      body.appendChild(p);
      body.scrollTop = body.scrollHeight;
    }
  };
  es.onerror = () => {
    es.close();
    const p = document.createElement('p');
    p.textContent = 'Error en el stream de progreso.';
    body.appendChild(p);
  };
});

// refrescar logs cada 10s
setInterval(()=>{
  fetch("{{ url_for('honeypot_logs') }}")
    .then(r=>r.text())
    .then(html=>{
      document.getElementById('logs-body').innerHTML = html;
    });
},10000);
</script>
</body></html>"""

@app.route('/login', methods=['GET','POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        if (form.username.data == os.environ.get('APP_USER') and
            form.password.data == os.environ.get('APP_PASS')):
            session['logged'] = True
            return redirect(url_for('scan'))
    return render_template_string(login_template, form=form)

@app.route('/logout')
@login_required
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/', methods=['GET'])
@app.route('/scan', methods=['GET'])
@login_required
def scan():
    logs = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, newline='') as f:
            logs = list(csv.DictReader(f))
    logs.sort(key=lambda l: l['timestamp'], reverse=True)
    return render_template_string(
        scan_template,
        stream_url = url_for('scan_stream'),
        logs=logs
    )

@app.route('/honeypot_logs')
@login_required
def honeypot_logs():
    rows = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, newline='') as f:
            for l in csv.DictReader(f):
                rows.append(f"<tr><td>{l['timestamp']}</td><td>{l['ip']}</td>"
                            f"<td>{l['port']}</td><td>{l['protocol']}</td>"
                            f"<td>{l['info']}</td></tr>")
    rows.reverse()
    return "\n".join(rows)

@app.route('/scan_stream')
@login_required
def scan_stream():
    ip = request.args.get('ip')
    def sse(msg):
        return f"data: {msg}\\n\\n"
    def generator():
        yield sse(f"Iniciando escaneo de {ip}")
        nm = nmap.PortScanner()
        nm.scan(ip, arguments='-sV')
        hosts = nm.all_hosts()
        target = ip if ip in hosts else (hosts[0] if hosts else None)
        scan_data = nm[target].get('tcp', {}) if target else {}
        yield sse(f"Puertos encontrados: {len(scan_data)}")
        services = []
        for port,info in scan_data.items():
            svc = f"{info.get('name','')} {info.get('product','')} {info.get('version','')}".strip()
            yield sse(f"Analizando puerto {port} – {svc}")
            vulns = requests.post(
                "https://vulners.com/api/v3/search/lucene/",
                json={'query':f"{info.get('product','')} {info.get('version','')}"}
            ).json().get('data',{}).get('search',[])
            services.append({'port':port,'service':svc,'vulnerabilities':vulns})
            yield sse(f"Vulnerabilidades: {len(vulns)}")
        now = dt.now().strftime('%Y%m%d_%H%M%S')
        folder = f"{ip}_{now}"
        full   = os.path.join(REPORT_DIR, folder)
        os.makedirs(full, exist_ok=True)
        report = {'ip':ip,'timestamp':now,'services':services}
        with open(os.path.join(full,'report.json'),'w') as f:
            json.dump(report, f, indent=2)
        yield sse("DONE")
    return Response(generator(), content_type='text/event-stream')

@app.route('/reports/<name>/download')
@login_required
def download_report(name):
    return send_from_directory(os.path.join(REPORT_DIR,name), 'report.json', as_attachment=True)

if __name__ == '__main__':
    init_log_file()
    for p in HONEYPOT_PORTS:
        free_port(p)
        threading.Thread(target=start_honeypot, args=(p,), daemon=True).start()
    app_port = find_free_port()
    GUNICORN_PORT = app_port
    def _open():
        time.sleep(1)
        webbrowser.open(f"http://127.0.0.1:{app_port}/scan")
    threading.Thread(target=_open, daemon=True).start()
    app.run(host='0.0.0.0', port=app_port)
