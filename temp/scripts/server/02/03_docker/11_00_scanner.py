import argparse
import os
import json
from datetime import datetime
import nmap

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--target', required=True, help='IP o rango a escanear')
    parser.add_argument('-o', '--output', default='reports', help='Carpeta de salida')
    return parser.parse_args()

def ensure_output_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def run_scan(target):
    scanner = nmap.PortScanner()
    scanner.scan(hosts=target, arguments='-sV -O --script vuln')
    return scanner

def build_report(scanner, target):
    report = {'target': target, 'timestamp': datetime.now().isoformat(), 'hosts': []}
    for host in scanner.all_hosts():
        host_data = {'ip': host, 'status': scanner[host].state()}
        ports = []
        for proto in scanner[host].all_protocols():
            for port in scanner[host][proto]:
                svc = scanner[host][proto][port]
                ports.append({
                    'port': port,
                    'protocol': proto,
                    'service': svc.get('name'),
                    'version': svc.get('version'),
                    'script_results': svc.get('script', {})
                })
        host_data['ports'] = ports
        osmatches = scanner[host].get('osmatch', [])
        host_data['os'] = [{'name': o.get('name'), 'accuracy': o.get('accuracy')} for o in osmatches]
        report['hosts'].append(host_data)
    return report

def save_report(report, output_dir, target):
    timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    fname = f"{timestamp}_{target.replace('/', '_')}.json"
    path = os.path.join(output_dir, fname)
    with open(path, 'w') as f:
        json.dump(report, f, indent=2)
    return path

def main():
    args = parse_args()
    ensure_output_dir(args.output)
    scanner = run_scan(args.target)
    report = build_report(scanner, args.target)
    path = save_report(report, args.output, args.target)
    print(f"Informe guardado en: {path}")

if __name__ == '__main__':
    main()
