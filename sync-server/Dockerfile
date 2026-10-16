# Opportunex sync server — stores end-to-end encrypted records it cannot read.
# Build:  docker build -t opportunex-sync:1.0.0 .
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN groupadd --system app && useradd --system --gid app --home /app app
WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY opx_sync ./opx_sync
RUN mkdir -p /app/data && chown -R app:app /app
USER app

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/v1/health', timeout=4).status == 200 else 1)"

# JSON-free plain logs contain no user content (the server never sees any).
CMD ["uvicorn", "opx_sync.app:get_app", "--factory", "--host", "0.0.0.0", "--port", "8080", "--proxy-headers", "--forwarded-allow-ips", "*"]
