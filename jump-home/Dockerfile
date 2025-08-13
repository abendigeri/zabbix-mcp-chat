FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# Install system dependencies (first pass)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    jq \
    vim \
    nano \
    git \
    nodejs \
    npm \
    htop \
    net-tools \
    iputils-ping \
    telnet \
    netcat \
    unzip \
    tree \
    ca-certificates \
    gnupg \
    software-properties-common \
    gcc \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.13 and make it default
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    python3.13-distutils \
    && ln -sf /usr/bin/python3.13 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.13 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.13
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.13

# Install pip for Python 3.13
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.13

# Install Python packages for testing
RUN python3.13 -m pip install --no-cache-dir \
    requests \
    httpx \
    websockets \
    fastapi \
    uvicorn \
    mcp \
    ollama \
    pytest \
    jupyter \
    ipython \
    black \
    flake8 \
    mypy

# Create workspace directory
WORKDIR /root

# Create useful aliases and environment setup
RUN echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias la="ls -la"' >> ~/.bashrc && \
    echo 'alias ..="cd .."' >> ~/.bashrc && \
    echo 'alias py="python3.13"' >> ~/.bashrc && \
    echo 'alias python="python3.13"' >> ~/.bashrc && \
    echo 'alias pip="python3.13 -m pip"' >> ~/.bashrc && \
    echo 'alias pip3="python3.13 -m pip"' >> ~/.bashrc && \
    echo 'export PS1="\[\033[01;32m\]\u@jump-server\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc && \
    echo 'echo "🐍 Python $(python3.13 --version) ready!"' >> ~/.bashrc

# Copy workspace files
COPY . /root/

# Make scripts executable
RUN find /root -name "*.py" -exec chmod +x {} \; && \
    find /root -name "*.sh" -exec chmod +x {} \;

# Expose common development ports
EXPOSE 8888 8889 8890 3000 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8888 || exit 1

# Start with bash and keep container running
CMD ["/bin/bash", "-c", "echo 'Jump Server Ready! 🚀'; echo 'Python: $(python3.13 --version)'; echo 'Available tools: curl, jq, python3.13, node, git, vim'; echo 'Workspace: /root'; echo 'Services accessible via container names (e.g., zabbix-web:8080)'; echo 'Type: ./test-services.sh to test all services'; exec /bin/bash"]
