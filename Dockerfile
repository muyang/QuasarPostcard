FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy backend requirements and install
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ .

# Copy pre-built Flutter web app (must exist at backend/static/app/)
# Build it first: cd card-designer && flutter build web && cp -r build/web backend/static/app
COPY backend/static/app/ ./static/app/

# Create data directory for SQLite
RUN mkdir -p /app/data

ENV DB_PATH=sqlite:////app/data/postcard.db

EXPOSE 8100

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8100/api/health || exit 1

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8100"]
