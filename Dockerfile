# Dockerfile volontairement naïf : image lourde, root, pas de cache de couches, pas de HEALTHCHECK.
# Il sera corrigé au TP04.
FROM python:3.13
COPY . /app
WORKDIR /app
RUN pip install .
CMD uvicorn app.main:app --host 0.0.0.0 --port 8000
