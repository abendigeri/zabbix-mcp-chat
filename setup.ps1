# Setup script for Windows PowerShell

Write-Host "🔧 Setting up Zabbix MCP Chatbot environment..." -ForegroundColor Cyan

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "📝 Creating default .env file..." -ForegroundColor Yellow
    
    $envContent = @"
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
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ Created .env file - please update ZABBIX_TOKEN with your actual token" -ForegroundColor Green
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

# Check Docker installation
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker is installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed or not accessible" -ForegroundColor Red
    Write-Host "💡 Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
}

# Check Docker Compose
try {
    $composeVersion = docker-compose --version
    Write-Host "✅ Docker Compose is available: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose is not available" -ForegroundColor Red
}

Write-Host ""
Write-Host "🚀 Setup complete! You can now run:" -ForegroundColor Green
Write-Host "  .\start.ps1   - Start all services" -ForegroundColor White
Write-Host "  .\stop.ps1    - Stop all services" -ForegroundColor White  
Write-Host "  .\monitor.ps1 - Monitor service status" -ForegroundColor White
Write-Host ""
Write-Host "📝 Don't forget to update your ZABBIX_TOKEN in the .env file!" -ForegroundColor Yellow
