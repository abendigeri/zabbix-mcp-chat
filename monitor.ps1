# Zabbix MCP Chatbot Stack - PowerShell Monitoring Script

Write-Host "🔍 Zabbix MCP Chatbot Stack Status" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Function to check service health
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [int]$Port = 0,
        [string]$Path = ""
    )
    
    $isRunning = (docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String "$ServiceName.*Up") -ne $null
    
    if ($isRunning) {
        if ($Port -gt 0 -and $Path) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$Port$Path" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    Write-Host "✅ $ServiceName`: Running and healthy" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  $ServiceName`: Running but not responding on port $Port" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "⚠️  $ServiceName`: Running but not responding on port $Port" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✅ $ServiceName`: Running" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ $ServiceName`: Not running" -ForegroundColor Red
    }
}

# Check individual services
Write-Host "📋 Service Status:" -ForegroundColor White
Test-ServiceHealth "zabbix-db"
Test-ServiceHealth "zabbix-server"
Test-ServiceHealth "zabbix-web" 8080 "/api_jsonrpc.php"
Test-ServiceHealth "ollama" 11434 "/api/tags"
Test-ServiceHealth "zabbix-mcp" 8000 "/health"
Test-ServiceHealth "chatbot" 9000 "/health"
Test-ServiceHealth "open-webui" 3000
Test-ServiceHealth "jump-server"

Write-Host ""
Write-Host "🌐 Service URLs:" -ForegroundColor Cyan
Write-Host "  - Zabbix Web UI: http://localhost:8080" -ForegroundColor White
Write-Host "  - Chatbot: http://localhost:9000" -ForegroundColor White
Write-Host "  - Open WebUI: http://localhost:3000" -ForegroundColor White
Write-Host "  - MCP Server: http://localhost:8000" -ForegroundColor White
Write-Host "  - Ollama API: http://localhost:11434" -ForegroundColor White

Write-Host ""
Write-Host "📊 Docker Compose Status:" -ForegroundColor White
docker-compose ps

Write-Host ""
Write-Host "💾 Volume Usage:" -ForegroundColor White
docker system df

Write-Host ""
Write-Host "🔧 Quick Commands:" -ForegroundColor Yellow
Write-Host "  - View all logs: docker-compose logs" -ForegroundColor White
Write-Host "  - View service logs: docker-compose logs [service-name]" -ForegroundColor White
Write-Host "  - Restart service: docker-compose restart [service-name]" -ForegroundColor White
Write-Host "  - Stop all: docker-compose down" -ForegroundColor White
Write-Host "  - Start all: docker-compose up -d" -ForegroundColor White

# Check for any unhealthy containers
Write-Host ""
Write-Host "🏥 Health Checks:" -ForegroundColor White
$unhealthy = docker ps --filter "health=unhealthy" --format "table {{.Names}}\t{{.Status}}"
if ($unhealthy) {
    Write-Host "⚠️  Unhealthy containers found:" -ForegroundColor Yellow
    Write-Host $unhealthy
} else {
    Write-Host "✅ All containers are healthy" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 Recent Activity (last 10 lines):" -ForegroundColor White
try {
    docker-compose logs --tail=10 chatbot zabbix-mcp 2>$null | Select-Object -Last 20
}
catch {
    Write-Host "No recent logs available" -ForegroundColor Gray
}
