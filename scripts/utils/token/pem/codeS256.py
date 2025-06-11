import os
import base64
import hashlib

code_verifier = base64.urlsafe_b64encode(os.urandom(40)).decode('utf-8').rstrip('=')
code_challenge = base64.urlsafe_b64encode(hashlib.sha256(code_verifier.encode('utf-8')).digest()).decode('utf-8').rstrip('=')

with open('codes_s256.txt', 'w') as f:
    f.write(f"Code Verifier: {code_verifier}\n")
    f.write(f"Code Challenge (S256): {code_challenge}\n")

print("Code Verifier:", code_verifier)
print("Code Challenge (S256):", code_challenge)
