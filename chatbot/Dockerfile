FROM python:3.11-slim

WORKDIR /app

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip to latest version
RUN pip install --upgrade pip setuptools wheel

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies with better conflict resolution
RUN pip install --no-cache-dir --upgrade anyio sniffio typing-extensions && \
    pip install --no-cache-dir -r requirements.txt || \
    (echo "Trying alternative installation method..." && \
     pip install --no-cache-dir fastapi uvicorn[standard] httpx python-multipart jinja2 ollama && \
     pip install --no-cache-dir --no-deps mcp)

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 chatbot && chown -R chatbot:chatbot /app
USER chatbot

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9000/health || exit 1

ENV PORT=9000
EXPOSE 9000

CMD ["python", "app.py"]

