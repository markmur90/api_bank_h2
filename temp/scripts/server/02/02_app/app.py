from dotenv import load_dotenv
load_dotenv()
from flask import Flask, render_template_string, request, redirect, url_for, session, send_from_directory
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, IPAddress
import os, datetime, json, nmap, requests
from functools import wraps


login_template = """
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="d-flex align-items-center justify-content-center vh-100">
    <form method="post" class="p-4 border rounded bg-light">
        {{ form.hidden_tag() }}
        <div class="mb-3">{{ form.username.label }}{{ form.username(class_='form-control') }}</div>
        <div class="mb-3">{{ form.password.label }}{{ form.password(class_='form-control') }}</div>
        <div>{{ form.submit(class_='btn btn-primary w-100') }}</div>
    </form>
</body>
</html>
"""

scan_template = """
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Escanear IP</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="p-4">
    <a href="{{ url_for('logout') }}" class="btn btn-sm btn-danger mb-3">Cerrar sesión</a>
    <form method="post" class="mb-4">
        {{ form.hidden_tag() }}
        <div class="input-group">
            {{ form.ip(class_='form-control', placeholder='127.0.0.1') }}
            <button class="btn btn-primary">{{ form.submit.label.text }}</button>
        </div>
    </form>
    <a href="{{ url_for('list_reports') }}">Ver reportes existentes</a>
</body>
</html>
"""

list_template = """
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Reportes</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="p-4">
    <a href="{{ url_for('scan') }}" class="btn btn-sm btn-secondary mb-3">Nuevo escaneo</a>
    <ul class="list-group">
    {% for r in reports %}
        <li class="list-group-item d-flex justify-content-between align-items-center">
            {{ r }}
            <div>
                <a href="{{ url_for('view_report', name=r) }}" class="btn btn-sm btn-info">Ver</a>
                <a href="{{ url_for('download_report', name=r) }}" class="btn btn-sm btn-success">Descargar JSON</a>
            </div>
        </li>
    {% endfor %}
    </ul>
</body>
</html>
"""

report_template = """
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Reporte {{ report.ip }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="p-4">
    <a href="{{ url_for('list_reports') }}" class="btn btn-sm btn-secondary mb-3">Volver a reportes</a>
    <h1>IP: {{ report.ip }}</h1>
    <p>Fecha: {{ report.timestamp }}</p>
    <table class="table table-striped">
        <thead><tr><th>Puerto</th><th>Servicio</th><th>#Vulnerabilidades</th></tr></thead>
        <tbody>
        {% for s in report.services %}
            <tr>
                <td>{{ s.port }}</td>
                <td>{{ s.service }}</td>
                <td>{{ s.vulnerabilities|length }}</td>
            </tr>
        {% endfor %}
        </tbody>
    </table>
</body>
</html>
"""

class LoginForm(FlaskForm):
    username = StringField('Usuario', validators=[DataRequired()])
    password = PasswordField('Contraseña', validators=[DataRequired()])
    submit = SubmitField('Ingresar')

class ScanForm(FlaskForm):
    ip = StringField('Dirección IP', validators=[DataRequired(), IPAddress()])
    submit = SubmitField('Escanear')

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'cambiar_esto_depresión')
REPORT_DIR = os.path.join(app.root_path, 'reports')
os.makedirs(REPORT_DIR, exist_ok=True)

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('logged'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

@app.route('/login', methods=['GET','POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        if form.username.data == os.environ.get('APP_USER','admin') and form.password.data == os.environ.get('APP_PASS','secret'):
            session['logged'] = True
            return redirect(url_for('scan'))
    return render_template_string(login_template, form=form)

@app.route('/logout')
@login_required
def logout():
    session.clear()
    return redirect(url_for('login'))

def scan_ip(ip):
    nm = nmap.PortScanner()
    nm.scan(ip, arguments='-sV')
    return nm[ip].get('tcp', {})

def query_vulners(product, version):
    q = f'{product} {version}'
    url = 'https://vulners.com/api/v3/search/lucene/'
    r = requests.post(url, json={'query': q})
    data = r.json()
    return data.get('data', {}).get('search', [])

def generate_report(ip, scan_data):
    now = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    folder = f'{ip}_{now}'
    full = os.path.join(REPORT_DIR, folder)
    os.makedirs(full, exist_ok=True)
    report = {'ip': ip, 'timestamp': now, 'services': []}
    for port, info in scan_data.items():
        svc = f"{info.get('name','')} {info.get('product','')} {info.get('version','')}".strip()
        vulns = query_vulners(info.get('product',''), info.get('version',''))
        report['services'].append({'port': port, 'service': svc, 'vulnerabilities': vulns})
    path = os.path.join(full, 'report.json')
    with open(path, 'w') as f:
        json.dump(report, f, indent=2)
    return folder

@app.route('/', methods=['GET','POST'])
@app.route('/scan', methods=['GET','POST'])
@login_required
def scan():
    form = ScanForm()
    if form.validate_on_submit():
        folder = generate_report(form.ip.data, scan_ip(form.ip.data))
        return redirect(url_for('view_report', name=folder))
    return render_template_string(scan_template, form=form)

@app.route('/reports')
@login_required
def list_reports():
    reports = sorted(os.listdir(REPORT_DIR), reverse=True)
    return render_template_string(list_template, reports=reports)

@app.route('/reports/<name>/download')
@login_required
def download_report(name):
    return send_from_directory(os.path.join(REPORT_DIR, name), 'report.json', as_attachment=True)

@app.route('/reports/<name>')
@login_required
def view_report(name):
    path = os.path.join(REPORT_DIR, name, 'report.json')
    with open(path) as f:
        report = json.load(f)
    return render_template_string(report_template, report=report)

if __name__ == '__main__':
    app.run(ssl_context='adhoc', host='0.0.0.0', port=5001)
