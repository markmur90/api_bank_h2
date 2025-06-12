# parse_ids_alerts.py
import json
from collections import Counter

ALERT_LOG = "/var/log/suricata/eve.json"

def classify_alerts(path):
    severities = Counter()
    with open(path, "r") as f:
        for line in f:
            try:
                event = json.loads(line)
                if event.get("event_type") == "alert":
                    severity = event.get("alert", {}).get("severity", -1)
                    if severity == 1:
                        severities["Alta"] += 1
                    elif severity == 2:
                        severities["Media"] += 1
                    elif severity == 3:
                        severities["Baja"] += 1
            except json.JSONDecodeError:
                continue
    return severities

if __name__ == "__main__":
    resumen = classify_alerts(ALERT_LOG)
    print("🧾 Clasificación de alertas IDS:")
    for nivel, count in resumen.items():
        print(f"{nivel}: {count}")
