#!/bin/bash
# Zabbix MCP Chatbot Stack - Startup Script

echo "🚀 Starting Zabbix MCP Chatbot Stack..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please create it with your configuration."
    echo "   See .env.example for template"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "📋 Loading environment configuration..."
source .env

echo "🧹 Cleaning up any existing containers..."
docker-compose down

echo "📦 Building custom images..."
docker-compose build --no-cache

echo "🔄 Starting infrastructure services (DB, Zabbix, Ollama)..."
docker-compose up -d db zabbix-server zabbix-web ollama

echo "⏳ Waiting for Zabbix Web UI to be ready..."
timeout=300
counter=0
until curl -s http://localhost:8080/api_jsonrpc.php > /dev/null || [ $counter -eq $timeout ]; do
    echo "   Waiting for Zabbix Web UI... ($counter/$timeout seconds)"
    sleep 10
    counter=$((counter + 10))
done

if [ $counter -eq $timeout ]; then
    echo "❌ Zabbix Web UI failed to start within $timeout seconds"
    echo "📋 Check logs: docker-compose logs zabbix-web"
    exit 1
fi

echo "✅ Zabbix Web UI is ready!"

echo "🤖 Waiting for Ollama to be ready..."
until curl -s http://localhost:11434/api/tags > /dev/null; do
    echo "   Waiting for Ollama..."
    sleep 5
done

echo "📥 Pulling Ollama model: $OLLAMA_MODEL"
curl -X POST http://localhost:11434/api/pull \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$OLLAMA_MODEL\"}" \
    --silent --show-error

echo "🔧 Starting MCP Server and Chatbot..."
docker-compose up -d zabbix-mcp chatbot

echo "⏳ Waiting for services to be healthy..."
sleep 15

echo "✅ All services started!"
echo ""
echo "🌐 Access URLs:"
echo "  - Zabbix Web UI: http://localhost:8080 (Admin/zabbix)"
echo "  - Chatbot: http://localhost:9000"
echo "  - Open WebUI: http://localhost:3000"
echo "  - MCP Server: http://localhost:8000"
echo "  - Ollama API: http://localhost:11434"
echo ""
echo "📊 Check status with: docker-compose ps"
echo "📋 Check logs with: docker-compose logs -f [service-name]"
echo ""
echo "🔧 Starting remaining services..."
docker-compose up -d

echo "🎉 Complete stack is now running!"
