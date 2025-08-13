# Chatbot Dependency Troubleshooting Guide

## Common Dependency Conflicts

### Issue: `mcp 1.0.0 depends on anyio>=4.6`

This error occurs when there are version conflicts between packages that depend on different versions of `anyio`.

### Solutions (try in order):

## Solution 1: Use Updated Requirements
The main `requirements.txt` has been updated with compatible versions.

## Solution 2: Manual Dependency Resolution
If the main requirements still fail, try this manual approach:

```bash
# In the chatbot directory
pip install --upgrade pip setuptools wheel
pip install anyio>=4.6.0 sniffio>=1.3.0
pip install mcp==1.0.0
pip install fastapi uvicorn ollama httpx python-multipart jinja2
```

## Solution 3: Use Minimal Requirements
If conflicts persist, use the minimal requirements file:

```dockerfile
# In Dockerfile, replace the requirements line with:
COPY requirements-minimal.txt requirements.txt
```

## Solution 4: Use Different MCP Library
If `mcp` package continues to conflict, consider alternatives:

```txt
# Replace in requirements.txt:
# mcp==1.0.0
# with:
httpx>=0.25.0
websockets>=11.0.0
# Then modify app.py to use direct HTTP calls instead of MCP client
```

## Solution 5: Pin All Versions
Create a fully pinned requirements.txt:

```bash
# Generate from working environment:
pip freeze > requirements-pinned.txt
```

## Debugging Commands

```bash
# Check dependency conflicts:
pip check

# Show dependency tree:
pip show mcp
pip show anyio

# Install with verbose output:
pip install -v mcp==1.0.0

# Force reinstall:
pip install --force-reinstall mcp==1.0.0
```

## Docker Build Debugging

```bash
# Build with no cache to see all steps:
docker build --no-cache -t chatbot-debug .

# Build only up to dependency installation:
docker build --target <stage> .

# Run interactive container to debug:
docker run -it python:3.11-slim bash
# Then manually run the pip commands
```

## Alternative Approach: Use Poetry or pipenv

If pip continues to have issues, consider using Poetry for dependency management:

```toml
# pyproject.toml
[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.104.1"
uvicorn = {extras = ["standard"], version = "^0.24.0"}
mcp = "^1.0.0"
ollama = "^0.1.7"
httpx = "^0.25.2"
python-multipart = "^0.0.6"
jinja2 = "^3.1.2"
```

Then update Dockerfile:
```dockerfile
RUN pip install poetry
COPY pyproject.toml .
RUN poetry install --no-dev
```
