# Docker Build Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: `python3.13-distutils` package not found

**Error**: `E: Unable to locate package python3.13-distutils`

**Cause**: The `distutils` package was deprecated in Python 3.12+ and is no longer available as a separate package.

**Solution**: Remove `python3.13-distutils` from the package list. It's now included in `setuptools`.

### Issue 2: uv/pipx installation issues

**Error**: `/app/venv/bin/pip: not found` or various errors with `pipx` or `uv` installation

**Cause**: `uv venv` creates virtual environments without pip installed by default.

**Solutions**:

1. **Use the stable Dockerfile approach** (Recommended):
   ```bash
   # Uses official Python 3.13 image - most reliable
   # Already configured in docker-compose.yml
   docker-compose build zabbix-mcp
   ```

2. **Use the simple Dockerfile approach**:
   ```bash
   # Edit docker-compose.yml to use Dockerfile.simple
   dockerfile: Dockerfile.simple
   ```

3. **Fix the complex Dockerfile**:
   ```dockerfile
   # Use direct pip installation instead of uv
   RUN python3.13 -m pip install -r requirements.txt
   ```

### Issue 3: Build context issues

**Error**: Build fails to find files or contexts

**Solution**: Ensure you're running docker-compose from the project root:
```bash
cd zabbix-mcp-chat
docker-compose build
```

### Issue 4: Dependency conflicts

**Error**: Package version conflicts during pip install

**Solutions**:

1. **Use alternative requirements**:
   ```bash
   # For zabbix-mcp-server
   cp requirements-simple.txt requirements.txt
   ```

2. **Build with no cache**:
   ```bash
   docker-compose build --no-cache
   ```

3. **Clean Docker build cache**:
   ```bash
   docker builder prune -a
   ```

## Build Strategies

### Strategy 1: Incremental fixing
```bash
# Build services one by one to isolate issues
docker-compose build jump-server
docker-compose build zabbix-mcp  
docker-compose build chatbot
```

### Strategy 2: Use alternative Dockerfiles
```bash
# For zabbix-mcp-server
cd zabbix-mcp-server
mv Dockerfile Dockerfile.backup
mv Dockerfile.simple Dockerfile
cd ..
docker-compose build zabbix-mcp
```

### Strategy 3: Debug interactively
```bash
# Start with base image and debug step by step
docker run -it ubuntu:22.04 bash
# Then manually run the problematic commands
```

## Quick Fixes

### Fix 1: Python 3.13 installation
```dockerfile
# Remove python3.13-distutils from installation
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    && rm -rf /var/lib/apt/lists/*
```

### Fix 2: Simplified dependency installation
```dockerfile
# Use get-pip.py instead of package manager
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.13
RUN python3.13 -m pip install --upgrade pip setuptools wheel
```

### Fix 3: Use proven base images
```dockerfile
# Instead of building Python 3.13 from scratch
FROM python:3.13-slim
# Much more reliable
```

## Environment Variables for Debugging

```bash
# Enable verbose Docker build output
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0

# Build with more verbose output
docker-compose build --progress=plain --no-cache
```

## Alternative Approaches

### Option 1: Use Python 3.11 (more stable)
```dockerfile
FROM python:3.11-slim
# Proven stable, widely tested
```

### Option 2: Multi-stage builds
```dockerfile
# Build stage
FROM ubuntu:22.04 as builder
# ... build Python 3.13 and install packages

# Runtime stage  
FROM ubuntu:22.04 as runtime
COPY --from=builder /opt/python3.13 /opt/python3.13
```

### Option 3: Use official Python images
```dockerfile
FROM python:3.13-rc-slim
# Use release candidate if stable 3.13 not available
```

## Testing Your Fixes

```bash
# Test individual Dockerfiles
docker build -t test-jump-server ./jump-home
docker build -t test-zabbix-mcp ./zabbix-mcp-server  
docker build -t test-chatbot ./chatbot

# Test the fixed containers
docker run --rm test-jump-server python3.13 --version
docker run --rm test-zabbix-mcp python --version
```
