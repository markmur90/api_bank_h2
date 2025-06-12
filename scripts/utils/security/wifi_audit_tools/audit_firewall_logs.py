# audit_firewall_logs.py
import re
from datetime import datetime, timedelta

LOG_PATH = "/var/log/ufw.log"  # O cambia a tu ruta de logs iptables
SUSPICIOUS_PORTS = [23, 445, 3389]
TIME_WINDOW_HOURS = 24

def parse_log():
    now = datetime.now()
    limit = now - timedelta(hours=TIME_WINDOW_HOURS)
    suspicious = []

    with open(LOG_PATH, "r") as file:
        for line in file:
            match = re.search(r'\[(.*?)\].*SRC=(.*?) DST=(.*?) .*DPT=(\d+)', line)
            if match:
                timestamp_str, src_ip, dst_ip, port = match.groups()
                try:
                    log_time = datetime.strptime(timestamp_str, '%b %d %H:%M:%S')
                    log_time = log_time.replace(year=now.year)
                    if log_time > limit and int(port) in SUSPICIOUS_PORTS:
                        suspicious.append((log_time, src_ip, dst_ip, port))
                except ValueError:
                    continue
    return suspicious

if __name__ == "__main__":
    events = parse_log()
    if events:
        print("[!] Posibles conexiones sospechosas:")
        for e in events:
            print(f"{e[0]} | SRC: {e[1]} → DST: {e[2]} :{e[3]}")
    else:
        print("✅ Sin eventos críticos recientes.")
