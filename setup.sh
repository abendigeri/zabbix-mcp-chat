#!/bin/bash
# Setup script to make all shell scripts executable

echo "🔧 Setting up Zabbix MCP Chatbot environment..."

# Make scripts executable
chmod +x start.sh
chmod +x stop.sh  
chmod +x monitor.sh

# Make jump server scripts executable
chmod +x jump-home/test-services.sh

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating default .env file..."
    cat > .env << 'EOF'
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
EOF
    echo "✅ Created .env file - please update ZABBIX_TOKEN with your actual token"
else
    echo "✅ .env file already exists"
fi

echo ""
echo "🚀 Setup complete! You can now run:"
echo "  ./start.sh   - Start all services"
echo "  ./stop.sh    - Stop all services"
echo "  ./monitor.sh - Monitor service status"
echo ""
echo "📝 Don't forget to update your ZABBIX_TOKEN in the .env file!"
