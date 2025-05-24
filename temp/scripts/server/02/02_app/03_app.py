import os,datetime,json,nmap,requests,socket,subprocess,threading,csv
from datetime import datetime as dt
from dotenv import load_dotenv
load_dotenv()
from flask import Flask,render_template_string,request,redirect,url_for,session,send_from_directory,Response
from flask_wtf import FlaskForm
from wtforms import StringField,PasswordField,SubmitField
from wtforms.validators import DataRequired,IPAddress
from functools import wraps

HONEYPOT_IP="0.0.0.0"
HONEYPOT_PORTS=[2222,8000]
REAL_BACKEND="127.0.0.1"
GUNICORN_PORT=None
LOG_FILE="honeypot_logs.csv"
BANNER=b"SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2\r\n"
log_lock=threading.Lock()

def free_port(port):
    subprocess.run(f"lsof -ti:{port} | xargs -r kill -9",shell=True)

def init_log_file():
    if os.path.exists(LOG_FILE):os.remove(LOG_FILE)
    with open(LOG_FILE,'w',newline='') as f:csv.writer(f).writerow(["timestamp","ip","port","protocol","info"])

def log_attempt(ip,port,protocol,info):
    timestamp=dt.now().isoformat()
    with log_lock,open(LOG_FILE,'a',newline='') as f:csv.writer(f).writerow([timestamp,ip,port,protocol,info])

def handle_client(client,address,port):
    if port==2222:
        try:
            client.sendall(BANNER)
            data=client.recv(1024)
            if data:log_attempt(address[0],port,"SSH",data.decode(errors='ignore').strip())
        finally:client.close()
    elif port==8000:
        remote=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        try:
            remote.connect((REAL_BACKEND,GUNICORN_PORT))
            req=client.recv(4096)
            if req:
                first_line=req.decode(errors='ignore').splitlines()[0]
                log_attempt(address[0],port,"HTTP",first_line)
                remote.sendall(req)
                remote.shutdown(socket.SHUT_WR)
                while True:
                    c=remote.recv(4096)
                    if not c:break
                    client.sendall(c)
        except:pass
        finally:
            client.close()
            remote.close()

def start_honeypot(port):
    server=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
    server.bind((HONEYPOT_IP,port))
    server.listen(1000)
    while True:
        client,addr=server.accept()
        threading.Thread(target=handle_client,args=(client,addr,port),daemon=True).start()

login_template="""<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Login</title><link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet"></head><body class="d-flex align-items-center justify-content-center vh-100"><form method="post" class="p-4 border rounded bg-light">{{ form.hidden_tag() }}<div class="mb-3">{{ form.username.label }}{{ form.username(class_='form-control') }}</div><div class="mb-3">{{ form.password.label }}{{ form.password(class_='form-control') }}</div><div>{{ form.submit(class_='btn btn-primary w-100') }}</div></form></body></html>"""

scan_template="""<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Escanear IP</title><link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet"></head><body class="p-4"><a href="{{ url_for('logout') }}" class="btn btn-sm btn-danger mb-3">Cerrar sesión</a><form id="scan-form" class="mb-4"><div class="input-group"><input id="ip-input" name="ip" class="form-control" placeholder="127.0.0.1"><button id="scan-btn" class="btn btn-primary">Escanear</button></div></form><a href="{{ url_for('list_reports') }}">Ver reportes existentes</a><div class="modal fade" id="progressModal" tabindex="-1" aria-hidden="true"><div class="modal-dialog modal-lg"><div class="modal-content"><div class="modal-header"><h5 class="modal-title">Progreso de escaneo</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body" style="height:400px;overflow:auto;" id="progress-body"></div><div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button></div></div></div></div><script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"></script><script>const form=document.getElementById('scan-form'),ipInput=document.getElementById('ip-input'),modal=new bootstrap.Modal(document.getElementById('progressModal')),body=document.getElementById('progress-body');form.addEventListener('submit',e=>{e.preventDefault();body.innerHTML='';modal.show();const ip=ipInput.value;const es=new EventSource("{{ stream_url }}?ip="+encodeURIComponent(ip));es.onmessage=e=>{if(e.data==='DONE'){es.close();modal.hide();window.location.href=`/reports/${body.getAttribute('data-folder')}`;}else{if(e.data.startsWith('REPORT=')){body.setAttribute('data-folder',e.data.split('=')[1]);}else{const p=document.createElement('p');p.textContent=e.data;body.appendChild(p);body.scrollTop=body.scrollHeight;}}};es.onerror=()=>{es.close();const p=document.createElement('p');p.textContent='Error en el stream de progreso.';body.appendChild(p);};});</script></body></html>"""

list_template="""<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Reportes</title><link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet"></head><body class="p-4"><a href="{{ url_for('scan') }}" class="btn btn-sm btn-secondary mb-3">Nuevo escaneo</a><ul class="list-group">{% for r in reports %}<li class="list-group-item d-flex justify-content-between align-items-center">{{ r }}<div><a href="{{ url_for('view_report',name=r) }}" class="btn btn-sm btn-info">Ver</a><a href="{{ url_for('download_report',name=r) }}" class="btn btn-sm btn-success">Descargar JSON</a></div></li>{% endfor %}</ul></body></html>"""

report_template="""<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Reporte {{ report.ip }}</title><link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet"></head><body class="p-4"><a href="{{ url_for('list_reports') }}" class="btn btn-sm btn-secondary mb-3">Volver a reportes</a><h1>IP: {{ report.ip }}</h1><p>Fecha: {{ report.timestamp }}</p><table class="table table-striped"><thead><tr><th>Puerto</th><th>Servicio</th><th>#Vulnerabilidades</th></tr></thead><tbody>{% for s in report.services %}<tr><td>{{ s.port }}</td><td>{{ s.service }}</td><td>{{ s.vulnerabilities|length }}</td></tr>{% endfor %}</tbody></table></body></html>"""

honeypot_template="""<html><head><meta http-equiv="refresh" content="5"><title>Honeypot</title><style>body{font-family:Arial;padding:20px;}table{width:100%;border-collapse:collapse;}th,td{border:1px solid #ccc;padding:8px;}th{background:#f2f2f2;}</style></head><body><h1>Registro de intentos</h1><table><thead><tr><th>Fecha</th><th>IP</th><th>Puerto</th><th>Protocolo</th><th>Info</th></tr></thead><tbody>{% for l in logs %}<tr><td>{{ l.timestamp }}</td><td>{{ l.ip }}</td><td>{{ l.port }}</td><td>{{ l.protocol }}</td><td>{{ l.info }}</td></tr>{% endfor %}</tbody></table></body></html>"""

class LoginForm(FlaskForm):
    username=StringField('Usuario',validators=[DataRequired()])
    password=PasswordField('Contraseña',validators=[DataRequired()])
    submit=SubmitField('Ingresar')

class ScanForm(FlaskForm):
    ip=StringField('Dirección IP',validators=[DataRequired(),IPAddress()])
    submit=SubmitField('Escanear')

app=Flask(__name__)
app.config['SECRET_KEY']=os.environ.get('SECRET_KEY')
REPORT_DIR=os.path.join(app.root_path,'reports')
os.makedirs(REPORT_DIR,exist_ok=True)

def login_required(f):
    @wraps(f)
    def decorated(*args,**kwargs):
        if not session.get('logged'):return redirect(url_for('login'))
        return f(*args,**kwargs)
    return decorated

@app.route('/login',methods=['GET','POST'])
def login():
    form=LoginForm()
    if form.validate_on_submit():
        if form.username.data==os.environ.get('APP_USER') and form.password.data==os.environ.get('APP_PASS'):
            session['logged']=True
            return redirect(url_for('scan'))
    return render_template_string(login_template,form=form)

@app.route('/logout')
@login_required
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/',methods=['GET'])
@app.route('/scan',methods=['GET'])
@login_required
def scan():
    stream_url=url_for('scan_stream')
    return render_template_string(scan_template,stream_url=stream_url)

@app.route('/scan_stream')
@login_required
def scan_stream():
    ip=request.args.get('ip')
    return Response(stream_scan(ip),mimetype='text/event-stream')

@app.route('/reports')
@login_required
def list_reports():
    reports=sorted(os.listdir(REPORT_DIR),reverse=True)
    return render_template_string(list_template,reports=reports)

@app.route('/reports/<name>/download')
@login_required
def download_report(name):
    return send_from_directory(os.path.join(REPORT_DIR,name),'report.json',as_attachment=True)

@app.route('/reports/<name>')
@login_required
def view_report(name):
    with open(os.path.join(REPORT_DIR,name,'report.json')) as f:report=json.load(f)
    return render_template_string(report_template,report=report)

@app.route('/honeypot')
@login_required
def honeypot_dashboard():
    logs=[]
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE,newline='') as f:logs=list(csv.DictReader(f))
    logs.sort(key=lambda l:l['timestamp'],reverse=True)
    return render_template_string(honeypot_template,logs=logs)

def scan_ip(ip):
    nm=nmap.PortScanner();nm.scan(ip,arguments='-sV');return nm[ip].get('tcp',{})

def query_vulners(product,version):
    r=requests.post("https://vulners.com/api/v3/search/lucene/",json={'query':f"{product} {version}"})
    return r.json().get('data',{}).get('search',[])

def stream_scan(ip):
    yield f"Iniciando escaneo de {ip}\n"
    scan_data=scan_ip(ip);yield f"Puertos encontrados: {len(scan_data)}\n";services=[]
    for port,info in scan_data.items():
        svc=f"{info.get('name','')} {info.get('product','')} {info.get('version','')}".strip();yield f"Analizando puerto {port} - {svc}\n"
        vulns=query_vulners(info.get('product',''),info.get('version',''));services.append({'port':port,'service':svc,'vulnerabilities':vulns});yield f"Vulnerabilidades: {len(vulns)}\n"
    now=dt.now().strftime('%Y%m%d_%H%M%S');folder=f"{ip}_{now}";full=os.path.join(REPORT_DIR,folder);os.makedirs(full,exist_ok=True)
    report={'ip':ip,'timestamp':now,'services':services}
    with open(os.path.join(full,'report.json'),'w') as f:json.dump(report,f,indent=2)
    yield f"REPORT={folder}\n";yield "DONE\n"

def find_free_port(start=5000,end=5100):
    for p in range(start,end):
        with socket.socket(socket.AF_INET,socket.SOCK_STREAM) as s:
            try:s.bind(('0.0.0.0',p));return p
            except:continue
    raise RuntimeError("No free ports found")

if __name__=='__main__':
    init_log_file()
    for p in HONEYPOT_PORTS:
        free_port(p);threading.Thread(target=start_honeypot,args=(p,),daemon=True).start()
    app_port=find_free_port()
    GUNICORN_PORT=app_port
    app.run(host='0.0.0.0',port=app_port)
