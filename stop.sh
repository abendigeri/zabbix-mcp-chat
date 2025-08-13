#!/bin/bash
# Stop Zabbix MCP Chatbot Stack

echo "🛑 Stopping Zabbix MCP Chatbot Stack..."

# Function to check if containers are running
check_containers() {
    local running=$(docker-compose ps -q | wc -l)
    echo $running
}

# Function to wait for containers to stop
wait_for_stop() {
    local max_wait=60
    local wait_time=0
    
    while [ $(check_containers) -gt 0 ] && [ $wait_time -lt $max_wait ]; do
        echo "⏳ Waiting for containers to stop... ($wait_time/$max_wait seconds)"
        sleep 5
        wait_time=$((wait_time + 5))
    done
}

# Stop all services gracefully
echo "📊 Stopping application services..."
docker-compose stop chatbot open-webui

echo "🤖 Stopping AI services..."
docker-compose stop zabbix-mcp ollama

echo "📈 Stopping Zabbix services..."
docker-compose stop zabbix-web zabbix-server zabbix-agent2

echo "🗄️ Stopping database..."
docker-compose stop db

echo "🛠️ Stopping utility services..."
docker-compose stop jump-server

# Wait for graceful shutdown
wait_for_stop

# Force stop if needed
if [ $(check_containers) -gt 0 ]; then
    echo "⚠️ Some containers didn't stop gracefully, forcing shutdown..."
    docker-compose down
fi

echo ""
echo "✅ All services stopped!"
echo ""
echo "📋 Additional cleanup options:"
echo "  Remove containers: docker-compose down"
echo "  Remove volumes:    docker-compose down -v"
echo "  Remove images:     docker-compose down --rmi all"
echo "  Full cleanup:      docker-compose down -v --rmi all"
echo ""
echo "🔍 Check status: docker-compose ps"
