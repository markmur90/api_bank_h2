FROM python:3.10-slim-bullseye
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends nmap lsof && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
RUN chmod +x /app/entrypoint.sh
EXPOSE 2222 8000 5000
ENTRYPOINT ["/app/entrypoint.sh"]
