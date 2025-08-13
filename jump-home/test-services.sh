#!/bin/bash
# Jump Server Quick Test Script

echo "🔍 Jump Server Testing Suite"
echo "============================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test function
test_service() {
    local service_name=$1
    local url=$2
    local description=$3
    
    echo -e "${BLUE}Testing $description...${NC}"
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name is accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not accessible${NC}"
        return 1
    fi
}

# Test network connectivity
echo -e "${YELLOW}🌐 Network Connectivity Tests${NC}"
echo "----------------------------------------"

# Test internal services
test_service "Zabbix Web UI" "http://zabbix-web:8080" "Zabbix Web Interface"
test_service "Zabbix MCP Server" "http://zabbix-mcp:8000" "MCP Server API"
test_service "Ollama API" "http://ollama:11434/api/tags" "Ollama AI Service"
test_service "Chatbot" "http://chatbot:9000/health" "Chatbot Service"
test_service "PostgreSQL" "http://zabbix-db:5432" "Database Connection" || echo -e "${YELLOW}ℹ️ Database test via HTTP (expected to fail)${NC}"

echo ""
echo -e "${YELLOW}🔧 Environment Information${NC}"
echo "----------------------------------------"
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "Python Version: $(python3.13 --version)"
echo "Python Path: $(which python3.13)"
echo "Pip Version: $(python3.13 -m pip --version)"
echo "Node Version: $(node --version 2>/dev/null || echo 'Not installed')"
echo "Current Directory: $(pwd)"
echo "Available Files:"
ls -la

echo ""
echo -e "${YELLOW}🐍 Python 3.13 Verification${NC}"
echo "----------------------------------------"
if [ -f "/root/verify-python.py" ]; then
    echo "Running Python verification..."
    python3.13 /root/verify-python.py
else
    echo "Python verification script not found"
    echo "Basic Python test:"
    python3.13 -c "import sys; print(f'✅ Python {sys.version} working!')"
fi

echo ""
echo -e "${YELLOW}🐳 Docker Network Information${NC}"
echo "----------------------------------------"
# Show network information if available
if command -v ip &> /dev/null; then
    echo "Network Interfaces:"
    ip addr show | grep -E "(inet|docker|eth)" || echo "Network info not available"
fi

echo ""
echo -e "${YELLOW}🧪 MCP Testing${NC}"
echo "----------------------------------------"
if [ -f "/root/mcpdemo/test_script.py" ]; then
    echo "Running MCP test script..."
    cd /root/mcpdemo && python3.13 test_script.py
else
    echo "MCP test script not found at /root/mcpdemo/test_script.py"
fi

echo ""
echo -e "${GREEN}🎯 Quick Test Commands${NC}"
echo "----------------------------------------"
echo "# Verify Python 3.13 installation:"
echo "python3.13 /root/verify-python.py"
echo ""
echo "# Test Zabbix API directly:"
echo "curl -X POST http://zabbix-web:8080/api_jsonrpc.php -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"apiinfo.version\",\"id\":1}'"
echo ""
echo "# Test Ollama models:"
echo "curl http://ollama:11434/api/tags"
echo ""
echo "# Test Chatbot health:"
echo "curl http://chatbot:9000/health"
echo ""
echo "# Test MCP server:"
echo "curl http://zabbix-mcp:8000/health"
echo ""
echo "# Python interactive session:"
echo "python3.13"

echo ""
echo -e "${GREEN}✅ Jump Server Test Complete!${NC}"
