from datetime import datetime

def generar_mt103(trans_id, amount, sender, receiver):
    ahora = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    return f"""MT103
:{trans_id}
:32A:{ahora}EUR{amount}
:50K:{sender}
:59:{receiver}
:71A:SHA
"""

if __name__ == "__main__":
    contenido = generar_mt103("TRX998877", "1000000000", "KINPRO HOLDING GMBH", "UBS CH80A500B")
    print(contenido)
