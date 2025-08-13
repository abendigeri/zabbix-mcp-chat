FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg software-properties-common \
    gcc build-essential \
 && rm -rf /var/lib/apt/lists/*

# Install Python 3.13 and make it default
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    && ln -sf /usr/bin/python3.13 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.13 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.13
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.13

# Install Python dependencies directly (simpler approach)
COPY requirements.txt .
RUN python3.13 -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
    python3.13 -m pip install --no-cache-dir -r requirements.txt

# Copy app
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY config/ ./config/

EXPOSE 8000

# Start server using Python 3.13 directly
CMD ["python3.13", "scripts/start_server.py"]


