import os, csv, json, socket, threading, requests, webbrowser, time
from datetime import datetime as dt
from flask import Flask, request, render_template, jsonify, send_from_directory
from utils import scan_ports, advanced_scan, ssh_brute_force, generate_jwt, vulnerability_analysis, init_honeypot, find_free_port

app = Flask(__name__)
LOG_FILE = "honeypot_logs.csv"
REPORT_DIR = "reports"
os.makedirs(REPORT_DIR, exist_ok=True)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/honeypot_logs')
def honeypot_logs():
    logs = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, newline='') as f:
            logs = list(csv.DictReader(f))
    logs.sort(key=lambda l: l['timestamp'], reverse=True)
    return jsonify(logs)

@app.route('/scan_ports', methods=['POST'])
def api_scan_ports():
    ip = request.form['ip']
    start_port = int(request.form['start_port'])
    end_port = int(request.form['end_port'])
    result = scan_ports(ip, start_port, end_port)
    return jsonify(result)

@app.route('/advanced_scan', methods=['POST'])
def api_advanced_scan():
    data = request.form
    result = advanced_scan(data)
    return jsonify(result)

@app.route('/ssh_brute', methods=['POST'])
def api_ssh_brute():
    ip = request.form['ip']
    port = int(request.form['port'])
    threads = int(request.form['threads'])
    result = ssh_brute_force(ip, port, threads)
    return jsonify(result)

@app.route('/generate_jwt', methods=['POST'])
def api_generate_jwt():
    type_jwt = request.form['type']
    token = generate_jwt(type_jwt)
    return jsonify({"token": token})

@app.route('/vulnerability_analysis', methods=['POST'])
def api_vulnerability_analysis():
    target = request.form['target']
    result, folder = vulnerability_analysis(target, REPORT_DIR)
    return jsonify({"result": result, "folder": folder})

@app.route('/download/<folder>/<filename>')
def download_report(folder, filename):
    return send_from_directory(os.path.join(REPORT_DIR, folder), filename, as_attachment=True)

if __name__ == '__main__':
    threading.Thread(target=init_honeypot, args=(LOG_FILE,), daemon=True).start()
    
    puerto = find_free_port()

    def abrir_navegador():
        time.sleep(1)
        webbrowser.open(f"http://127.0.0.1:{puerto}")

    threading.Thread(target=abrir_navegador, daemon=True).start()

    app.run(debug=True, host='0.0.0.0', port=puerto)
