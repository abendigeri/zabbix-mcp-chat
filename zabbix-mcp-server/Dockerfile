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

# Create a startup script to handle dependencies
RUN echo '#!/bin/bash\n\
echo "Starting Zabbix MCP Server..."\n\
echo "Environment variables:"\n\
echo "  ZABBIX_URL: $ZABBIX_URL"\n\
echo "  ZABBIX_TOKEN: ${ZABBIX_TOKEN:+[SET]}"\n\
echo "  READ_ONLY: $READ_ONLY"\n\
echo "  DEBUG: $DEBUG"\n\
echo "  WAIT_FOR_ZABBIX: $WAIT_FOR_ZABBIX"\n\
\n\
if [ "$WAIT_FOR_ZABBIX" = "true" ]; then\n\
  echo "Waiting for Zabbix web service to be ready..."\n\
  max_attempts=30\n\
  attempt=0\n\
  \n\
  while [ $attempt -lt $max_attempts ]; do\n\
    if curl -sf "$ZABBIX_URL" >/dev/null 2>&1; then\n\
      echo "✅ Zabbix web service is ready!"\n\
      break\n\
    fi\n\
    echo "⏳ Waiting for Zabbix web service... ($((attempt+1))/$max_attempts)"\n\
    sleep 10\n\
    attempt=$((attempt+1))\n\
  done\n\
  \n\
  if [ $attempt -eq $max_attempts ]; then\n\
    echo "⚠️  Zabbix web service not ready after $((max_attempts*10)) seconds, starting anyway..."\n\
  fi\n\
fi\n\
\n\
echo "🚀 Starting MCP server..."\n\
exec python3.13 scripts/start_server.py' > /app/start.sh && chmod +x /app/start.sh

EXPOSE 8000

# Start server using the startup script
CMD ["/app/start.sh"]


