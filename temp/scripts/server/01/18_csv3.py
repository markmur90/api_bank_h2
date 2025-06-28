import os
import cv2
import numpy as np
import pandas as pd
from PIL import Image
import pytesseract
from datetime import datetime, timedelta
import sys
import json

def ask_questions():
    settings = {}
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_file = os.path.join(script_dir, 'config.json')
    saved = {}
    if os.path.exists(config_file):
        try:
            with open(config_file, 'r') as f:
                saved = json.load(f)
        except:
            saved = {}
    if saved:
        print("\n>>> Opciones guardadas detectadas. <<<")
        for k, v in saved.items():
            print(f"  • {k}: {v}")
        choice = input("¿Deseas cambiar las opciones guardadas? (s/N): ").strip().lower()
        if choice == 's': saved = {}
    questions = [
        ("¿Cuál es tu edad?", ["18-24", "25-34", "35-44", "45+"]),
        ("¿En qué mercado estás interesado?", ["Acciones", "Cripto", "Futuros", "Forex", "Materias primas"]),
        ("¿Con qué frecuencia analizarás el mercado?", ["Todo el día", "Unas pocas veces al día", "Cada pocos días", "Ocasionalmente"]),
        ("¿Tomarás mayores riesgos para obtener mayores recompensas?", ["Absolutamente", "Depende de la oportunidad", "Prefiero un riesgo equilibrado", "No, prefiero jugar a lo seguro"]),
        ("¿Qué tan bueno eres identificando oportunidades?", ["No tengo idea de por dónde empezar", "A veces solo adivino", "Acierto algunas, pero todavía me cuesta", "Confío en mis decisiones"]),
        ("¿Cómo te sientes analizando gráficos?", ["Demasiado complejo para mí", "No tengo tiempo", "Quiero aprender, pero no sé cómo", "Lo disfruto"]),
        ("¿Qué tipo de cuenta operas?", ["Pro Cent", "Standar", "Pro"]),
        ("¿Qué par vas a analizar?", ["EURUSD", "XAUUSD"]),
    ]
    keys = ['edad','mercado','frecuencia','riesgo','habilidad','sentimiento','cuenta','par']
    for i, (text, opts) in enumerate(questions):
        key = keys[i]
        if i < 6 and key in saved:
            settings[key] = saved[key]
            continue
        print(f"\n{'='*60}\n{text}\n{'='*60}")
        for idx, o in enumerate(opts, 1): print(f"  {idx}. {o}")
        while True:
            try:
                sel = int(input("➤ Selecciona número: "))
                if 1 <= sel <= len(opts):
                    settings[key] = opts[sel-1]
                    break
            except KeyboardInterrupt:
                sys.exit(0)
            except:
                pass
            print("  ¡Selección inválida!")
    to_save = {k: settings[k] for k in keys[:6]}
    try:
        with open(config_file, 'w') as f:
            json.dump(to_save, f, indent=2)
    except:
        pass
    modes = ['Image','CSV']
    print(f"\n{'='*60}\nSelecciona modo de análisis\n{'='*60}")
    for idx, m in enumerate(modes, 1): print(f"  {idx}. {m}")
    while True:
        try:
            sel = int(input("➤ Selecciona número: "))
            if 1 <= sel <= len(modes): settings['mode'] = modes[sel-1]; break
        except KeyboardInterrupt:
            sys.exit(0)
        except:
            pass
        print("  ¡Selección inválida!")
    print(f"\n{'='*60}\n¿Cuál es el monto actual de tu cuenta?\n{'='*60}")
    while True:
        try: settings['monto'] = float(input("➤ Monto: ")); break
        except KeyboardInterrupt: sys.exit(0)
        except: print("  ¡Valor inválido!")
    tfs = ["M1","M5","M15","M30","H1","D1","W1","MN"]
    print(f"\n{'='*60}\nSelecciona timeframe\n{'='*60}")
    for idx, tf in enumerate(tfs, 1): print(f"  {idx}. {tf}")
    while True:
        try: sel = int(input("➤ Número: ")); settings['timeframe'] = tfs[sel-1]; break
        except KeyboardInterrupt: sys.exit(0)
        except: print("  ¡Selección inválida!")
    print(f"\n{'='*60}\n¿Cuál es el máximo Drawdown (%)?\n{'='*60}")
    while True:
        try: settings['drawdown'] = float(input("➤ % Drawdown: ")); break
        except KeyboardInterrupt: sys.exit(0)
        except: print("  ¡Valor inválido!")
    return settings

def choose_image(folder):
    files = [f for f in os.listdir(folder) if f.lower().endswith(('.png','.jpg','.jpeg'))]
    if not files:
        print(f"No hay imágenes en {folder}")
        sys.exit(0)
    print(f"\nImágenes disponibles:\n{'#'*30}")
    for idx, f in enumerate(files, 1): print(f"  {idx}. {f}")
    while True:
        try: sel = int(input("➤ Selecciona imagen: ")); return os.path.join(folder, files[sel-1])
        except KeyboardInterrupt: sys.exit(0)
        except: print("  ¡Selección inválida!")

def analyze_chart(path):
    img = cv2.imread(path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150)
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, 100, minLineLength=100, maxLineGap=10)
    trend = 0 if lines is None else np.mean(np.diff(sorted([l[0][1] for l in lines])))
    return {'trend': trend, 'moment': datetime.now().strftime("%Y-%m-%d %H:%M:%S")}  

def analyze_csv(path):
    df = pd.read_csv(path)
    # get last three entry prices
    arr = None
    for col in ['entry_price','Entry_Price','EntryPrice','price','Price']:
        if col in df.columns:
            arr = df[col].dropna().astype(float).values
            break
    if arr is None:
        # fallback numeric first column
        for col in df.columns:
            if pd.api.types.is_numeric_dtype(df[col]):
                arr = df[col].dropna().astype(float).values
                break
    if arr is None:
        return {'moment': datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
    last3 = arr[-3:] if len(arr) >= 3 else arr
    return {'entry_prices': last3.tolist(), 'moment': datetime.now().strftime("%Y-%m-%d %H:%M:%S")}  

def compute_trade_for_entry(entry, analysis, settings):
    direction = 'BUY' if analysis.get('trend',0) < 0 else 'SELL'
    risk_pct = settings['drawdown']/100.0
    acct_mult = {"Pro Cent":0.01, "Standar":0.1, "Pro":1}[settings['cuenta']]
    lot = settings['monto'] * risk_pct * acct_mult
    if settings['cuenta'] == 'Pro Cent' and lot < 0.1:
        lot = 0.1
    trade = {'operacion':direction, 'momento':analysis.get('moment'), 'lotaje':round(lot,2), 'precio_entrada':round(entry,5)}
    if entry:
        if direction == 'BUY': stop, tp = entry*(1-risk_pct), entry*(1+risk_pct*2)
        else: stop, tp = entry*(1+risk_pct), entry*(1-risk_pct*2)
        pip_val = 0.0001 if settings['par']!='XAUUSD' else 0.01
        trade.update({'stop_loss':round(stop,5), 'take_profit':round(tp,5), 'pips_sl':int(abs((entry-stop)/pip_val)), 'pips_tp':int(abs((tp-entry)/pip_val))})
    return trade

def generate_trades(analysis, settings):
    trades = []
    if 'entry_prices' in analysis:
        for entry in analysis['entry_prices']:
            trades.append(compute_trade_for_entry(entry, analysis, settings))
    else:
        # image mode: single price, replicate for three dummy entries
        # ask user for 3 entries
        print("\nSe requieren 3 precios de entrada para generar 3 operaciones.")
        raw = input("Introduce 3 precios separados por coma: ")
        try:
            entries = [float(x.strip()) for x in raw.split(',')][:3]
        except:
            entries = []
        for entry in entries:
            trades.append(compute_trade_for_entry(entry, analysis, settings))
    return trades

if __name__=="__main__":
    try:
        settings = ask_questions()
        base = os.path.dirname(os.path.abspath(__file__))
        if settings['mode']=='Image':
            path = choose_image(os.path.join(base,'image'))
            analysis = analyze_chart(path)
        else:
            fname = f"{settings['par']}{settings['timeframe']}.csv"
            csv_dir = os.path.join(base,'csv')
            csv_path = os.path.join(csv_dir,fname)
            if not os.path.exists(csv_path):
                print(f"No existe {fname} en {csv_dir}.")
            # Listar archivos CSV manualmente
            files_csv = [f for f in os.listdir(csv_dir) if f.lower().endswith('.csv')]
            if not files_csv:
                print(f"No hay archivos CSV en {csv_dir}.")
                sys.exit(0)
            print(f"Archivos CSV disponibles en {csv_dir}:")
            for idx, f in enumerate(files_csv, 1):
                print(f"  {idx}. {f}")
            while True:
                try:
                    sel = int(input("➤ Selecciona archivo: "))
                    if 1 <= sel <= len(files_csv):
                        csv_path = os.path.join(csv_dir, files_csv[sel-1])
                        break
                except KeyboardInterrupt:
                    sys.exit(0)
                except:
                    pass
                print("  ¡Selección inválida!")
        analysis = analyze_csv(csv_path)
        trades = generate_trades(analysis,settings)
        print(f"\n{'='*60}\nRecomendación de operaciones:\n{'='*60}")
        for i,trade in enumerate(trades,1):
            print(f"\n--- Operación {i} ---")
            print(f"• Tipo           : {trade['operacion']}")
            print(f"• Momento        : {trade['momento']}")
            print(f"• Precio Entrada : {trade['precio_entrada']}")
            print(f"• Stop Loss      : {trade.get('stop_loss')} ({trade.get('pips_sl')} pips)")
            print(f"• Take Profit    : {trade.get('take_profit')} ({trade.get('pips_tp')} pips)")
            print(f"• Lotaje         : {trade['lotaje']}")
            delta_map = {'M1':timedelta(minutes=1),'M5':timedelta(minutes=5),'M15':timedelta(minutes=15),'M30':timedelta(minutes=30),'H1':timedelta(hours=1),'D1':timedelta(days=1),'W1':timedelta(days=7),'MN':timedelta(days=30)}
            est = (datetime.now()+delta_map[settings['timeframe']]).strftime("%Y-%m-%d %H:%M:%S")
            print(f"• Tiempo Estimado: {est}")
    except KeyboardInterrupt:
        print("\nInterrupción recibida. Saliendo.")
        sys.exit(0)
