# analyze_phishing_logs.py
import re

LOG_PATH = "/var/log/mail.log"  # Ajustar a postfix/exim
SUSPECT_PATTERNS = [
    r"(?i)urgent.*payment",
    r"http[s]?://.*bit\.ly",
    r"invoice.*\.zip",
    r"login.*\.php",
]

def detect_phishing():
    findings = []
    with open(LOG_PATH, "r") as f:
        for line in f:
            if any(re.search(pat, line) for pat in SUSPECT_PATTERNS):
                findings.append(line.strip())
    return findings

if __name__ == "__main__":
    suspicious = detect_phishing()
    if suspicious:
        print("[!] Correos sospechosos:")
        for line in suspicious:
            print(line)
    else:
        print("✅ No se detectaron correos sospechosos.")
