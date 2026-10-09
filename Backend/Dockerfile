FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
COPY seed.py ./seed.py
RUN useradd --create-home --uid 10001 lumina && chown -R lumina:lumina /app
USER lumina
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
