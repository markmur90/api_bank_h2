# temp/scripts/automate/escaneo/venice_api.py

import argparse
import requests
import json
import subprocess

def call_venice_api(text, model="modelo_especifico", temperature=0.7):
    url = "https://api.venice.ai/v1/process"
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer BLbgsEIf5TSv_CVcxJ4OYjYlQHXgP55nW5Zs1JCph8"
    }
    data = {
        "text": text,
        "parameters": {
            "model": model,
            "temperature": temperature
        }
    }

    response = requests.post(url, headers=headers, data=json.dumps(data))

    if response.status_code == 200:
        return response.json()
    else:
        return {"error": response.status_code, "message": response.text}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("text", help="Text to send to the API")
    args = parser.parse_args()

    result = call_venice_api(args.text)
    generated_text = result.get("generated_text", "No text generated")

    # Insertar texto en VSCode
    subprocess.run(["code", "--goto", f"{generated_text}:1:1"])