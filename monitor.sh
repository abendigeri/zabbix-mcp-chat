#!/bin/bash
# Zabbix MCP Chatbot Stack - Monitoring Script

echo "🔍 Zabbix MCP Chatbot Stack Status"
echo "=================================="

# Function to check service health
check_service() {
    local service=$1
    local port=$2
    local path=$3
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$service.*Up"; then
        if [ -n "$port" ] && [ -n "$path" ]; then
            if curl -s -f "http://localhost:$port$path" > /dev/null; then
                echo "✅ $service: Running and healthy"
            else
                echo "⚠️  $service: Running but not responding on port $port"
            fi
        else
            echo "✅ $service: Running"
        fi
    else
        echo "❌ $service: Not running"
    fi
}

# Check individual services
echo "📋 Service Status:"
check_service "zabbix-db"
check_service "zabbix-server"
check_service "zabbix-web" "8080" "/api_jsonrpc.php"
check_service "ollama" "11434" "/api/tags"
check_service "zabbix-mcp" "8000" "/health"
check_service "chatbot" "9000" "/health"
check_service "open-webui" "3000" ""
check_service "jump-server"

echo ""
echo "🌐 Service URLs:"
echo "  - Zabbix Web UI: http://localhost:8080"
echo "  - Chatbot: http://localhost:9000"
echo "  - Open WebUI: http://localhost:3000"
echo "  - MCP Server: http://localhost:8000"
echo "  - Ollama API: http://localhost:11434"

echo ""
echo "📊 Docker Compose Status:"
docker-compose ps

echo ""
echo "💾 Volume Usage:"
docker system df

echo ""
echo "🔧 Quick Commands:"
echo "  - View all logs: docker-compose logs"
echo "  - View service logs: docker-compose logs [service-name]"
echo "  - Restart service: docker-compose restart [service-name]"
echo "  - Stop all: docker-compose down"
echo "  - Start all: docker-compose up -d"

# Check for any unhealthy containers
echo ""
echo "🏥 Health Checks:"
unhealthy=$(docker ps --filter "health=unhealthy" --format "table {{.Names}}\t{{.Status}}")
if [ -n "$unhealthy" ]; then
    echo "⚠️  Unhealthy containers found:"
    echo "$unhealthy"
else
    echo "✅ All containers are healthy"
fi

echo ""
echo "📋 Recent Activity (last 10 lines):"
docker-compose logs --tail=10 chatbot zabbix-mcp 2>/dev/null | tail -20
