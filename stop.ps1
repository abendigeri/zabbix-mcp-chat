# Stop Zabbix MCP Chatbot Stack

Write-Host "🛑 Stopping Zabbix MCP Chatbot Stack..." -ForegroundColor Yellow

# Function to check if containers are running
function Get-RunningContainers {
    $containers = docker-compose ps -q
    if ($containers) {
        return ($containers | Measure-Object).Count
    }
    return 0
}

# Function to wait for containers to stop
function Wait-ForStop {
    $maxWait = 60
    $waitTime = 0
    
    while ((Get-RunningContainers) -gt 0 -and $waitTime -lt $maxWait) {
        Write-Host "⏳ Waiting for containers to stop... ($waitTime/$maxWait seconds)" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        $waitTime += 5
    }
}

try {
    # Stop all services gracefully
    Write-Host "📊 Stopping application services..." -ForegroundColor Cyan
    docker-compose stop chatbot open-webui

    Write-Host "🤖 Stopping AI services..." -ForegroundColor Cyan
    docker-compose stop zabbix-mcp ollama

    Write-Host "📈 Stopping Zabbix services..." -ForegroundColor Cyan
    docker-compose stop zabbix-web zabbix-server zabbix-agent2

    Write-Host "🗄️ Stopping database..." -ForegroundColor Cyan
    docker-compose stop db

    Write-Host "🛠️ Stopping utility services..." -ForegroundColor Cyan
    docker-compose stop jump-server

    # Wait for graceful shutdown
    Wait-ForStop

    # Force stop if needed
    if ((Get-RunningContainers) -gt 0) {
        Write-Host "⚠️ Some containers didn't stop gracefully, forcing shutdown..." -ForegroundColor Yellow
        docker-compose down
    }

    Write-Host ""
    Write-Host "✅ All services stopped!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Additional cleanup options:" -ForegroundColor Cyan
    Write-Host "  Remove containers: docker-compose down" -ForegroundColor White
    Write-Host "  Remove volumes:    docker-compose down -v" -ForegroundColor White
    Write-Host "  Remove images:     docker-compose down --rmi all" -ForegroundColor White
    Write-Host "  Full cleanup:      docker-compose down -v --rmi all" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 Check status: docker-compose ps" -ForegroundColor Cyan

} catch {
    Write-Host "❌ Error stopping services: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Try manual cleanup: docker-compose down" -ForegroundColor Yellow
    exit 1
}
