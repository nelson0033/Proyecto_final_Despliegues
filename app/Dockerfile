FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
ENV UVICORN_WORKERS=1
EXPOSE 8000
# 1 worker por contenedor: el escalado se hace con réplicas, no con procesos
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port 8000 --workers ${UVICORN_WORKERS}"]
