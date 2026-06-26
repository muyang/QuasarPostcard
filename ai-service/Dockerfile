FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/app/models/hf_cache

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-dev \
    libgl1 libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Python deps (torch first for CUDA build, then rest)
COPY requirements.txt .
RUN pip3 install --upgrade pip && \
    pip3 install torch==2.5.1 --index-url https://download.pytorch.org/whl/cu124 && \
    pip3 install -r requirements.txt

# App code
COPY app.py pipeline.py face_utils.py ./

ENV MODEL_CACHE_DIR=/app/models \
    EAGER_LOAD=1

# Health check: /health always returns 200 once uvicorn starts.
# Long start-period lets the container boot without being killed
# during model download (first run downloads ~5GB).
HEALTHCHECK --interval=30s --timeout=10s --start-period=600s --retries=3 \
    CMD curl -sf http://localhost:8000/health || exit 1

EXPOSE 8000
CMD ["python3", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
