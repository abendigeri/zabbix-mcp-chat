# Zabbix MCP Chatbot

A comprehensive monitoring chatbot system that integrates Zabbix monitoring with AI-powered assistance using Ollama and Model Context Protocol (MCP).

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │    │   Open WebUI    │    │   Jump Server   │
│  (Port: 9000)   │    │  (Port: 3000)   │    │  (Port: 8888)   │
└─────────┬───────┘    └─────────┬───────┘    └─────────────────┘
          │                      │
          │                      │
┌─────────▼───────┐    ┌─────────▼───────┐    ┌─────────────────┐
│    Chatbot      │    │     Ollama      │    │  Zabbix Web UI  │
│  (Port: 9000)   │◄───┤  (Port: 11434)  │    │  (Port: 8080)   │
└─────────┬───────┘    └─────────────────┘    └─────────┬───────┘
          │                                             │
          │                                             │
┌─────────▼───────┐    ┌─────────────────┐    ┌─────────▼───────┐
│  Zabbix MCP     │    │  PostgreSQL DB  │    │  Zabbix Server  │
│  (Port: 8000)   │    │  (Port: 5432)   │    │  (Port: 10051)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features

- **AI-Powered Monitoring Assistant**: Chat with your Zabbix infrastructure using natural language
- **Full Zabbix Integration**: Complete monitoring stack with database, server, web UI, and agent
- **Local AI Processing**: Ollama for GPU-accelerated inference
- **Model Context Protocol**: Secure and efficient API communication
- **Multiple Interfaces**: Custom chatbot UI and Open WebUI
- **Docker Orchestration**: Complete containerized deployment
- **Health Monitoring**: Built-in health checks for all services
- **Development Tools**: Jump server for testing and debugging

## 📋 Prerequisites

### System Requirements
- **OS**: Windows 10/11, Linux, or macOS
- **RAM**: Minimum 8GB (16GB recommended)
- **GPU**: NVIDIA GPU with CUDA support (optional but recommended)
- **Storage**: 20GB free space

### Software Dependencies
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (latest version)
- [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop)
- [Git](https://git-scm.com/downloads)

### NVIDIA GPU Setup (Optional)
If you have an NVIDIA GPU, install:
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- CUDA-compatible drivers

## 🛠️ Installation

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd zabbix-mcp-chat
```

### 2. Initial Setup

#### Windows (PowerShell)
```powershell
.\setup.ps1
```

#### Linux/macOS
```bash
chmod +x setup.sh
./setup.sh
```

This setup script will:
- Make all shell scripts executable (Linux/macOS)
- Create a default `.env` file if it doesn't exist
- Check Docker installation
- Display next steps

### 3. Configure Environment
Update the `.env` file created by the setup script with your actual Zabbix configuration:
```bash
# Zabbix Configuration
ZABBIX_URL=http://zabbix-web:8080
ZABBIX_TOKEN=your_api_token_here

# MCP Server Configuration  
READ_ONLY=true
DEBUG=1

# Chatbot Configuration
MCP_URL=http://zabbix-mcp:8000/mcp
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=qwen2.5:3b-instruct

# Database Configuration
POSTGRES_USER=zabbix
POSTGRES_PASSWORD=zabbix
POSTGRES_DB=zabbix
```

### 4. Build and Start Services

#### Windows (PowerShell)
```powershell
# Start the stack
.\start.ps1

# Stop the stack
.\stop.ps1
```

#### Linux/macOS
```bash
# Make scripts executable
chmod +x start.sh stop.sh

# Start the stack
./start.sh

# Stop the stack
./stop.sh
```

#### Manual Start
```bash
# Build custom images
docker-compose build

# Start infrastructure services first
docker-compose up -d db zabbix-server zabbix-web

# Wait for services to be ready (check logs)
docker-compose logs -f zabbix-web

# Start AI and chatbot services
docker-compose up -d ollama zabbix-mcp chatbot

# Start optional services
docker-compose up -d open-webui jump-server
```

### 5. Stop Services

#### Graceful Shutdown
```bash
# Windows
.\stop.ps1

# Linux/macOS
./stop.sh
```

#### Manual Stop Options
```bash
# Stop all services
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes
docker-compose down -v

# Complete cleanup (containers, volumes, images)
docker-compose down -v --rmi all
```

## 🌐 Access URLs

Once all services are running:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Zabbix Web UI** | http://localhost:8080 | Admin / zabbix |
| **Chatbot Interface** | http://localhost:9000 | - |
| **Open WebUI** | http://localhost:3000 | - |
| **MCP Server API** | http://localhost:8000 | - |
| **Ollama API** | http://localhost:11434 | - |
| **Jump Server** | `docker exec -it jump-server bash` | - |

## 🤖 Using the Chatbot

### Example Queries

1. **Monitor Problems**:
   - "Show me recent critical problems"
   - "List all high severity alerts"
   - "What problems occurred in the last 24 hours?"

2. **Host Information**:
   - "List all hosts"
   - "Show host status"
   - "Get information about host docker-host"

3. **System Status**:
   - "Check API version"
   - "Show server information"
   - "Get system status"

### Chatbot Interface Features

- **Natural Language Processing**: Ask questions in plain English
- **Structured Responses**: Get formatted data and JSON results
- **Error Handling**: Clear error messages and suggestions
- **Health Monitoring**: Real-time service status
- **Tool Discovery**: List available MCP tools

## 🔧 Configuration

### Zabbix Setup

1. **Access Zabbix Web UI**: http://localhost:8080
2. **Default Login**: Admin / zabbix
3. **Generate API Token**:
   - Go to Administration → Users
   - Click on Admin user
   - Go to API tokens tab
   - Create new token
   - Copy token to `.env` file

### Ollama Model Management

```bash
# List available models
docker exec ollama ollama list

# Pull additional models
docker exec ollama ollama pull llama3.1:8b
docker exec ollama ollama pull codellama:7b

# Update model in .env file
OLLAMA_MODEL=llama3.1:8b
```

### MCP Server Configuration

Edit `zabbix-mcp-server/config/mcp.json`:
```json
{
  "mcpServers": {
    "zabbix": {
      "command": "python",
      "args": ["/app/src/zabbix_mcp_server.py"],
      "env": {
        "ZABBIX_URL": "http://zabbix-web:8080",
        "READ_ONLY": "true"
      }
    }
  }
}
```

## 📊 Monitoring and Troubleshooting

### Check Service Status

#### Windows (PowerShell)
```powershell
.\monitor.ps1
```

#### Linux/macOS
```bash
./monitor.sh
```

#### Stop Services
```bash
# Windows
.\stop.ps1

# Linux/macOS  
./stop.sh
```

#### Manual Checks
```bash
# Check all services
docker-compose ps

# Check service health
docker-compose ps --format "table {{.Names}}\t{{.Status}}"

# View service logs
docker-compose logs chatbot
docker-compose logs zabbix-mcp
docker-compose logs ollama

# Check health endpoints
curl http://localhost:9000/health
curl http://localhost:8000/health
curl http://localhost:11434/api/tags
```

### Common Issues

#### 1. Zabbix Web UI Not Accessible
```bash
# Check database connection
docker-compose logs db

# Check Zabbix server logs
docker-compose logs zabbix-server

# Restart services
docker-compose restart zabbix-server zabbix-web
```

#### 2. Chatbot Connection Errors
```bash
# Check MCP server health
curl http://localhost:8000/health

# Check Ollama connection
curl http://localhost:11434/api/tags

# Check chatbot logs
docker-compose logs chatbot
```

#### 3. GPU Not Detected
```bash
# Check NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Update docker-compose.yml if needed
docker-compose up -d ollama
```

#### 4. Memory Issues
```bash
# Check resource usage
docker stats

# Reduce model size in .env
OLLAMA_MODEL=qwen2.5:1.5b-instruct
```

## 🔄 Service Lifecycle Management

### Quick Start/Stop Commands

| Platform | Start | Stop | Monitor |
|----------|-------|------|---------|
| **Windows** | `.\start.ps1` | `.\stop.ps1` | `.\monitor.ps1` |
| **Linux/macOS** | `./start.sh` | `./stop.sh` | `./monitor.sh` |

### Service Dependencies

The services start in this order:
1. **Database** (PostgreSQL)
2. **Zabbix Server** (depends on database)
3. **Zabbix Web UI** (depends on server + database)
4. **Ollama** (AI inference engine)
5. **Zabbix MCP Server** (depends on Zabbix Web UI)
6. **Chatbot** (depends on MCP + Ollama)
7. **Open WebUI** (depends on Ollama)
8. **Jump Server** (utility container)

### Cleanup Options

```bash
# Stop services gracefully
./stop.sh  # or .\stop.ps1

# Remove containers only
docker-compose down

# Remove containers and volumes (⚠️ data loss)
docker-compose down -v

# Complete cleanup (⚠️ removes everything)
docker-compose down -v --rmi all

# Remove only unused Docker resources
docker system prune
```

## 🧪 Development and Testing

### Using Jump Server
```bash
# Access jump server
docker exec -it jump-server bash

# Verify Python 3.13 installation
python3.13 /root/verify-python.py

# Run comprehensive service tests
./test-services.sh

# Test MCP connectivity
cd /root/mcpdemo
python3.13 test_script.py

# Test Zabbix API directly
curl -X POST http://zabbix-web:8080/api_jsonrpc.php \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"apiinfo.version","id":1}'

# Test Ollama models
curl http://ollama:11434/api/tags

# Test individual services
curl http://chatbot:9000/health
curl http://zabbix-mcp:8000/health

# Start Python 3.13 interactive session
python3.13
```

### Jump Server Features
- **Python 3.13**: Latest Python version with all development packages
- **Development Tools**: Git, Vim, curl, jq, htop, etc.
- **Node.js**: For JavaScript development
- **Testing Framework**: pytest, ipython, jupyter
- **Network Tools**: ping, telnet, netcat for connectivity testing
- **Code Quality**: black, flake8, mypy for Python code analysis

### Development Workflow
```bash
# Rebuild specific service
docker-compose build chatbot
docker-compose up -d chatbot

# View real-time logs
docker-compose logs -f chatbot zabbix-mcp

# Test changes
curl -X POST http://localhost:9000/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"List all hosts"}'
```

## 🔐 Security Considerations

### Production Deployment
1. **Change Default Passwords**:
   - Zabbix admin password
   - PostgreSQL password

2. **API Token Security**:
   - Use read-only tokens
   - Rotate tokens regularly
   - Store in secure environment variables

3. **Network Security**:
   - Use Docker secrets for sensitive data
   - Implement reverse proxy with SSL
   - Restrict network access

4. **Container Security**:
   - Use non-root users
   - Scan images for vulnerabilities
   - Keep images updated

## 📁 Project Structure

```
zabbix-mcp-chat/
├── docker-compose.yml          # Main orchestration file
├── .env                        # Environment configuration
├── setup.ps1                   # Windows setup script
├── setup.sh                    # Linux/macOS setup script
├── start.ps1                   # Windows startup script
├── start.sh                    # Linux/macOS startup script
├── stop.ps1                    # Windows stop script
├── stop.sh                     # Linux/macOS stop script
├── monitor.ps1                 # Windows monitoring script
├── monitor.sh                  # Linux/macOS monitoring script
├── README.md                   # This file
├── chatbot/                    # Chatbot application
│   ├── app.py                  # FastAPI application
│   ├── Dockerfile              # Container definition
│   ├── requirements.txt        # Python dependencies
│   └── static/
│       └── index.html          # Web interface
├── zabbix-mcp-server/          # MCP server implementation
│   ├── Dockerfile              # Container definition
│   ├── requirements.txt        # Python dependencies
│   ├── src/
│   │   └── zabbix_mcp_server.py # MCP server code
│   ├── scripts/
│   │   ├── start_server.py     # Server startup
│   │   └── test_server.py      # Server testing
│   └── config/
│       └── mcp.json            # MCP configuration
├── jump-home/                  # Jump server workspace
│   ├── Dockerfile              # Jump server container (Python 3.13)
│   ├── test-services.sh        # Service testing script
│   ├── verify-python.py        # Python 3.13 verification script
│   ├── app/
│   │   └── test_script.py      # Testing scripts
│   └── mcpdemo/
│       ├── mcp.json            # MCP demo config
│       └── test_script.py      # MCP testing
└── scripts/                    # Utility scripts
    └── setup-ollama.sh         # Ollama setup script
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly
5. Commit: `git commit -am 'Add feature'`
6. Push: `git push origin feature-name`
7. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Issues**: Open GitHub issues for bugs and feature requests
- **Documentation**: Check this README and code comments
- **Community**: Join discussions in GitHub Discussions

## 🔄 Updates and Changelog

### Version 1.0.0
- Initial release
- Full Zabbix integration
- Ollama AI support
- Docker orchestration
- Web interface

---

**Happy Monitoring! 🚀**
