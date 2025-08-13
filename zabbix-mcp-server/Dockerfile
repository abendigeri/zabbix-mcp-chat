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
    python3.13 python3.13-venv python3.13-dev \
 && ln -sf /usr/bin/python3.13 /usr/bin/python3 \
 && ln -sf /usr/bin/python3.13 /usr/bin/python \
 && rm -rf /var/lib/apt/lists/*

# Install uv via pipx (uses Python 3.13 by default now)
#RUN pipx install uv && uv --version

# Install Python dependencies
COPY requirements.txt .
#RUN uv pip install --system -r requirements.txt && \
#    uv pip install --system fastmcp  # ensures fastmcp is available

# Copy app
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY config/ ./config/

EXPOSE 8000

# Start server with python pointing to 3.13
CMD ["tail", "-f", "/dev/null"]


