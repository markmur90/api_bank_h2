import os
import time
import threading
import socket
import subprocess
import csv
import importlib.util
import io
import contextlib
import json
import webbrowser
from datetime import datetime as dt
from flask import Flask, render_template_string, request, redirect, url_for, session, send_from_directory, Response
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired
from functools import wraps

HONEYPOT_IP = "0.0.0.0"
HONEYPOT_PORTS = [2222, 8000]
REAL_BACKEND = "127.0.0.1"
LOG_FILE = "honeypot_logs.csv"
REPORT_DIR = "reports"
BANNER = b"SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2\r\n"
APP_USER = "markmur88"
APP_PASS = "Ptf8454Jd55"
SECRET_KEY = "QFGVA3UpZtpJJW3QDH6RvcsliyKpOP_rIbG-Ot5CYDQ"

app = Flask(__name__)
app.config['SECRET_KEY'] = SECRET_KEY
os.makedirs(REPORT_DIR, exist_ok=True)
log_lock = threading.Lock()

def init_log_file():
    if os.path.exists(LOG_FILE):
        os.remove(LOG_FILE)
    with open(LOG_FILE, 'w', newline='') as f:
        csv.writer(f).writerow(["timestamp", "ip", "port", "protocol", "info"])

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
    <div>
      <a href="{{ url_for('scan') }}" class="btn btn-primary">Scanner</a>
      <a href="{{ url_for('list_reports') }}" class="btn btn-secondary">Reportes</a>
      <a href="{{ url_for('tools') }}" class="btn btn-info">Herramientas</a>
    </div>
    <a href="{{ url_for('logout') }}" class="btn btn-danger">Cerrar sesión</a>
  </div>
  <div class="card mb-4" style="max-height:600px; overflow-y:auto;">
    <div class="card-header">Honeypot Logs (completo)</div>
    <div class="card-body p-0">
      <table class="table table-striped mb-0">
        <thead><tr><th>Timestamp</th><th>IP</th><th>Port</th><th>Protocol</th><th>Info</th></tr></thead>
        <tbody>
          {% for l in logs %}
            <tr><td>{{ l.timestamp }}</td><td>{{ l.ip }}</td><td>{{ l.port }}</td><td>{{ l.protocol }}</td><td>{{ l.info }}</td></tr>
          {% endfor %}
        </tbody>
      </table>
    </div>
  </div>
  <div id="honeypot-card" class="card fixed-bottom mx-auto" style="width:20rem; height:400px; z-index:999;">
    <div class="card-header">Último Evento Honeypot</div>
    <div class="card-body p-2" style="height:calc(100% - 40px); overflow-y:auto;">
      <table class="table table-sm mb-0"><thead><tr><th>Time</th><th>IP</th><th>Port</th><th>Proto</th><th>Info</th></tr></thead>
      <tbody id="honeypot-body"></tbody></table>
    </div>
  </div>
<script>
function fetchHoney(){
  fetch('/honeypot_logs').then(r=>r.text()).then(txt=>{
    let tmp=document.createElement('tbody');
    tmp.innerHTML=txt;
    let fila=tmp.querySelector('tr');
    document.getElementById('honeypot-body').innerHTML=fila?fila.outerHTML:'';
  });
}
fetchHoney(); setInterval(fetchHoney,5000);
</script>
</body></html>"""

list_template = """<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Reportes</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head><body class="p-4">
  <div class="d-flex justify-content-between mb-4">
    <h1>Reportes</h1>
    <div>
      <a href="{{ url_for('scan') }}" class="btn btn-primary">Scanner</a>
      <a href="{{ url_for('list_reports') }}" class="btn btn-secondary">Reportes</a>
      <a href="{{ url_for('tools') }}" class="btn btn-info">Herramientas</a>
    </div>
    <a href="{{ url_for('logout') }}" class="btn btn-danger">Cerrar sesión</a>
  </div>
  {% for pref, items in groups.items() %}
    <div class="card mb-4">
      <div class="card-header">Herramienta {{ pref }}</div>
      <div class="card-body">
        <ul class="list-group">
          {% for r in items %}
            <li class="list-group-item d-flex justify-content-between align-items-center">
              {{ r }} <a href="{{ url_for('view_report',name=r) }}" class="btn btn-sm btn-info">Ver</a>
            </li>
          {% endfor %}
        </ul>
      </div>
    </div>
  {% endfor %}
</body></html>"""


tools_template = """<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Herramientas</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head><body class="p-4" style="padding-bottom:240px;">
  <div class="d-flex justify-content-between mb-4">
    <h1>Herramientas</h1>
    <div>
      <a href="{{ url_for('scan') }}" class="btn btn-primary">Scanner</a>
      <a href="{{ url_for('list_reports') }}" class="btn btn-secondary">Reportes</a>
      <a href="{{ url_for('tools') }}" class="btn btn-info">Herramientas</a>
    </div>
    <a href="{{ url_for('logout') }}" class="btn btn-danger">Cerrar sesión</a>
  </div>
    <div class="card-header">Herramientas</div>
    <div class="card-body">
      <div class="mb-4">
        <h5>01_conection.py</h5>
        <form id="form01" class="row gx-2 gy-2 align-items-end">
          <div class="col-auto">
            <label for="DNS_server_Domain" class="form-label">DNS_server_Domain</label>
            <input type="text" id="DNS_server_Domain" class="form-control form-control-sm" placeholder="160.83.58.33">
          </div>
          <div class="col-auto">
            <label for="Puerto_HTTPS" class="form-label">Puerto_HTTPS</label>
            <input type="text" id="Puerto_HTTPS" class="form-control form-control-sm" placeholder="443">
          </div>
          <div class="col-auto">
            <label for="Host_SSH" class="form-label">Host_SSH</label>
            <input type="text" id="Host_SSH" class="form-control form-control-sm" placeholder="193.150.166.1">
          </div>
          <div class="col-auto">
            <label for="Usuario_de_acceso" class="form-label">Usuario_de_acceso</label>
            <input type="text" id="Usuario_de_acceso" class="form-control form-control-sm" placeholder="deutschebank@AS8373">
          </div>
          <div class="col-auto">
            <label for="PIN_de_autorizacion" class="form-label">PIN_de_autorizacion</label>
            <input type="text" id="PIN_de_autorizacion" class="form-control form-control-sm" placeholder="02569S">
          </div>
          <div class="col-auto">
            <button type="button" class="btn btn-primary btn-sm" onclick="run('01')">Ejecutar</button>
          </div>
        </form>
      </div>
      <div class="mb-4">
        <h5>02_conection.py</h5>
        <form id="form02" class="row gx-2 gy-2 align-items-end">
          <div class="col-auto">
            <label for="USER" class="form-label">USER</label>
            <input type="text" id="USER" class="form-control form-control-sm" placeholder="deutschebank@AS8373">
          </div>
          <div class="col-auto">
            <label for="AUTHORIZATION_PIN" class="form-label">AUTHORIZATION_PIN</label>
            <input type="text" id="AUTHORIZATION_PIN" class="form-control form-control-sm" placeholder="02569S">
          </div>
          <div class="col-auto">
            <label for="CFO_PIN" class="form-label">CFO_PIN</label>
            <input type="text" id="CFO_PIN" class="form-control form-control-sm" placeholder="54082">
          </div>
          <div class="col-auto">
            <label for="SSN" class="form-label">SSN</label>
            <input type="text" id="SSN" class="form-control form-control-sm" placeholder="0211676">
          </div>
          <div class="col-auto">
            <label for="CLIENT_NO" class="form-label">CLIENT_NO</label>
            <input type="text" id="CLIENT_NO" class="form-control form-control-sm" placeholder="000000000SRTRN38837862BEH1RLN000000">
          </div>
          <div class="col-auto">
            <label for="DB_IDENTITY_CODE" class="form-label">DB_IDENTITY_CODE</label>
            <input type="text" id="DB_IDENTITY_CODE" class="form-control form-control-sm" placeholder="27C DB FR DE 17BEN">
          </div>
          <div class="col-auto">
            <label for="TRANSACTION_ID" class="form-label">TRANSACTION_ID</label>
            <input type="text" id="TRANSACTION_ID" class="form-control form-control-sm" placeholder="090s12500700100958886479">
          </div>
          <div class="col-auto">
            <label for="SERVER" class="form-label">SERVER</label>
            <input type="text" id="SERVER" class="form-control form-control-sm" placeholder="https://api.db.com:443/gw/dbapi/banking/transactions/v2">
          </div>
          <div class="col-auto">
            <label for="PORT" class="form-label">PORT</label>
            <input type="text" id="PORT" class="form-control form-control-sm" placeholder="443">
          </div>
          <div class="col-auto">
            <button type="button" class="btn btn-primary btn-sm" onclick="run('02')">Ejecutar</button>
          </div>
        </form>
      </div>
      <div class="mb-4">
        <h5>03_conection.py</h5>
        <form id="form03" class="row gx-2 gy-2 align-items-end">
          <div class="col-auto">
            <label for="IP_PRINCIPAL_DEL_SERVIDOR" class="form-label">IP_PRINCIPAL_DEL_SERVIDOR</label>
            <input type="text" id="IP_PRINCIPAL_DEL_SERVIDOR" class="form-control form-control-sm" placeholder="193.150.166.1">
          </div>
          <div class="col-auto">
            <label for="PUERTO_DE_CONEXION" class="form-label">PUERTO_DE_CONEXION</label>
            <input type="text" id="PUERTO_DE_CONEXION" class="form-control form-control-sm" placeholder="443">
          </div>
          <div class="col-auto">
            <label for="CLIENTE_VPN" class="form-label">CLIENTE_VPN</label>
            <input type="text" id="CLIENTE_VPN" class="form-control form-control-sm" placeholder="openconnect">
          </div>
          <div class="col-auto">
            <label for="USUARIO" class="form-label">USUARIO</label>
            <input type="text" id="USUARIO" class="form-control form-control-sm" placeholder="493069k1">
          </div>
          <div class="col-auto">
            <label for="PIN_AUTORIZACION" class="form-label">PIN_AUTORIZACION</label>
            <input type="text" id="PIN_AUTORIZACION" class="form-control form-control-sm" placeholder="02569S">
          </div>
          <div class="col-auto">
            <label for="URL_EBANKING" class="form-label">URL_EBANKING</label>
            <input type="text" id="URL_EBANKING" class="form-control form-control-sm" placeholder="https://api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer">
          </div>
          <div class="col-auto">
            <button type="button" class="btn btn-primary btn-sm" onclick="run('03')">Ejecutar</button>
          </div>
        </form>
      </div>
      <div class="mb-4">
        <h5>10escaneo.py</h5>
        <form id="form10" class="row gx-2 gy-2 align-items-end">
          <div class="col-auto">
            <label for="ip_start" class="form-label">IP Ini</label>
            <input type="text" id="ip_start" class="form-control form-control-sm" placeholder="192.168.1.1">
          </div>
          <div class="col-auto">
            <label for="ip_end" class="form-label">IP Fin</label>
            <input type="text" id="ip_end" class="form-control form-control-sm" placeholder="192.168.1.254">
          </div>
          <div class="col-auto">
            <label for="port_start" class="form-label">Puerto Ini</label>
            <input type="text" id="port_start" class="form-control form-control-sm" placeholder="20">
          </div>
          <div class="col-auto">
            <label for="port_end" class="form-label">Puerto Fin</label>
            <input type="text" id="port_end" class="form-control form-control-sm" placeholder="1024">
          </div>
          <div class="col-auto">
            <label for="users_file" class="form-label">Archivo usuarios</label>
            <input type="text" id="users_file" class="form-control form-control-sm" placeholder="/ruta/usuarios.txt">
          </div>
          <div class="col-auto">
            <label for="passwords_file" class="form-label">Archivo passwords</label>
            <input type="text" id="passwords_file" class="form-control form-control-sm" placeholder="/ruta/passwords.txt">
          </div>
          <div class="col-auto">
            <label for="selected_tools" class="form-label">Herramientas (números separados por espacio)</label>
            <input type="text" id="selected_tools" class="form-control form-control-sm" placeholder="1 2 3">
          </div>
          <div class="col-auto">
            <button type="button" class="btn btn-primary btn-sm" onclick="run('10')">Ejecutar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
  <div id="honeypot-card" class="card fixed-bottom mx-auto" style="width:80%; height:200px; z-index:999;">
    <div class="card-header">Último Evento Honeypot</div>
    <div class="card-body p-2" style="height:calc(100% - 40px); overflow-y:auto;">
      <table class="table table-sm mb-0"><thead><tr><th>Time</th><th>IP</th><th>Port</th><th>Proto</th><th>Info</th></tr></thead>
      <tbody id="honeypot-body"></tbody></table>
    </div>
  </div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
function run(id){
  let params=new URLSearchParams()
  let f=document.getElementById('form'+id)
  for(let inp of f.querySelectorAll('input')){
    if(inp.value) params.append(inp.id, inp.value)
  }
  const source=new EventSource('/run/'+id+'?'+params.toString())
  const modal=new bootstrap.Modal(document.getElementById('progressModal'))
  document.getElementById('progress-body').innerHTML=''
  modal.show()
  source.onmessage=e=>{
    if(e.data==='DONE'){ source.close(); modal.hide(); setTimeout(()=>window.location.href='/reports',500) }
    else{
      let p=document.createElement('p'); p.textContent=e.data
      document.getElementById('progress-body').appendChild(p)
      document.getElementById('progress-body').scrollTop=document.getElementById('progress-body').scrollHeight
    }
  }
  source.onerror=()=>{
    source.close()
    let p=document.createElement('p'); p.textContent='Error en la ejecución.'
    document.getElementById('progress-body').appendChild(p)
  }
}
function fetchHoney(){
  fetch('/honeypot_logs').then(r=>r.text()).then(txt=>{
    let tmp=document.createElement('tbody'); tmp.innerHTML=txt
    let fila=tmp.querySelector('tr')
    document.getElementById('honeypot-body').innerHTML=fila?fila.outerHTML:''
  })
}
fetchHoney(); setInterval(fetchHoney,5000)
</script>

<div class="modal fade" id="progressModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-lg"><div class="modal-content">
    <div class="modal-header"><h5 class="modal-title">Progreso</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
    <div class="modal-body" id="progress-body" style="height:300px;overflow:auto;"></div>
    <div class="modal-footer"><button class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button></div>
  </div></div>
</div>
</body></html>"""

report_card_template = """<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Reporte {{ name }}</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head><body class="p-4">
  <div class="d-flex justify-content-between mb-4">
    <div>
      <a href="{{ url_for('scan') }}" class="btn btn-primary">Scanner</a>
      <a href="{{ url_for('list_reports') }}" class="btn btn-secondary">Reportes</a>
      <a href="{{ url_for('tools') }}" class="btn btn-info">Herramientas</a>
    </div>
    <a href="{{ url_for('logout') }}" class="btn btn-danger">Cerrar sesión</a>
  </div>
  <div class="card mb-4">
    <div class="card-header"><h4>Reporte {{ name }}</h4></div>
    <div class="card-body" style="max-height:800px; overflow:auto;">
      <h5>JSON</h5>
      <pre>{{ json_data }}</pre>
      <hr/>
      <h5>Texto</h5>
      <pre>{{ txt_data }}</pre>
    </div>
    <div class="card-footer">
      <a href="{{ url_for('list_reports') }}" class="btn btn-secondary">Volver</a>
    </div>
  </div>
  <div id="honeypot-card" class="card fixed-bottom mx-auto" style="width:20rem; height:400px; z-index:999;">
    <div class="card-header">Último Evento Honeypot</div>
    <div class="card-body p-2" style="height:calc(100% - 40px); overflow-y:auto;">
      <table class="table table-sm mb-0">
        <thead><tr><th>Time</th><th>IP</th><th>Port</th><th>Proto</th><th>Info</th></tr></thead>
        <tbody id="honeypot-body"></tbody>
      </table>
    </div>
  </div>
<script>
function fetchHoney(){
  fetch('/honeypot_logs').then(r=>r.text()).then(txt=>{
    let tmp=document.createElement('tbody');
    tmp.innerHTML=txt;
    let fila=tmp.querySelector('tr');
    document.getElementById('honeypot-body').innerHTML=fila?fila.outerHTML:'';
  });
}
fetchHoney(); setInterval(fetchHoney,5000);
</script>
</body></html>"""



@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit() and form.username.data == APP_USER and form.password.data == APP_PASS:
        session['logged'] = True
        return redirect(url_for('scan'))
    return render_template_string(login_template, form=form)

@app.route('/logout')
@login_required
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/')
@app.route('/scan')
@login_required
def scan():
    logs = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, newline='') as f:
            logs = list(csv.DictReader(f))
    logs.sort(key=lambda l: l['timestamp'], reverse=True)
    return render_template_string(scan_template, logs=logs)

@app.route('/honeypot_logs')
@login_required
def honeypot_logs():
    rows = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, newline='') as f:
            for l in csv.DictReader(f):
                rows.append(f"<tr><td>{l['timestamp']}</td><td>{l['ip']}</td><td>{l['port']}</td><td>{l['protocol']}</td><td>{l['info']}</td></tr>")
    rows.reverse()
    return "".join(rows)

@app.route('/reports')
@login_required
def list_reports():
    files = sorted(os.listdir(REPORT_DIR), reverse=True)
    groups = {}
    for f in files:
        pref = f.split('_')[0]
        groups.setdefault(pref, []).append(f)
    return render_template_string(list_template, groups=groups)

@app.route('/tools')
@login_required
def tools():
    return render_template_string(tools_template)

@app.route('/run/<script>')
@login_required
def run_script(script):
    def sse(msg): return f"data: {msg}\n\n"
    def generator():
        params = request.args
        if script in ['01', '02', '03']:
            name = f"{script}_conection"
            path = f"{name}.py"
            yield sse(f"Iniciando {path}")
            out = io.StringIO()
            try:
                spec = importlib.util.spec_from_file_location(name, path)
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
                for key, val in params.items():
                    if hasattr(mod, key):
                        orig = getattr(mod, key)
                        try: setattr(mod, key, type(orig)(val))
                        except: setattr(mod, key, val)
                with contextlib.redirect_stdout(out):
                    mod.main()
                for l in out.getvalue().splitlines():
                    yield sse(l)
                now = dt.now().strftime('%Y%m%d_%H%M%S')
                full = os.path.join(REPORT_DIR, f"{script}_{now}")
                os.makedirs(full, exist_ok=True)
                with open(os.path.join(full, 'report.json'), 'w') as jf:
                    json.dump({"output": out.getvalue().splitlines()}, jf, indent=2)
                with open(os.path.join(full, 'report.txt'), 'w') as tf:
                    tf.write(out.getvalue())
            except Exception as e:
                yield sse(f"Error: {e}")
        else:
            yield sse("Iniciando 10escaneo.py")
            args = [
                params.get('ip_start', ''),
                params.get('ip_end', ''),
                params.get('port_start', ''),
                params.get('port_end', ''),
                params.get('users_file', ''),
                params.get('passwords_file', ''),
                params.get('selected_tools', '')
            ]
            proc = subprocess.Popen(["python3", "10escaneo.py", *args], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            lines = []
            for line in proc.stdout:
                lines.append(line.strip())
                yield sse(line.strip())
            now = dt.now().strftime('%Y%m%d_%H%M%S')
            full = os.path.join(REPORT_DIR, f"{script}_{now}")
            os.makedirs(full, exist_ok=True)
            with open(os.path.join(full, 'report.json'), 'w') as jf:
                json.dump({"output": lines}, jf, indent=2)
            with open(os.path.join(full, 'report.txt'), 'w') as tf:
                tf.write("\n".join(lines))
        yield sse("DONE")
    return Response(generator(), mimetype='text/event-stream', headers={'Cache-Control': 'no-cache'})

@app.route('/reports/<name>')
@login_required
def view_report(name):
    base = os.path.join(REPORT_DIR, name)
    with open(os.path.join(base, 'report.json')) as j, open(os.path.join(base, 'report.txt')) as t:
        jd = json.dumps(json.load(j), indent=2)
        td = t.read()
    return render_template_string(report_card_template, name=name, json_data=jd, txt_data=td)

@app.route('/reports/<name>/download')
@login_required
def download_report(name):
    return send_from_directory(os.path.join(REPORT_DIR, name), 'report.json', as_attachment=True)

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
