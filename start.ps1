# Zabbix MCP Chatbot Stack - PowerShell Startup Script
param(
    [switch]$SkipChecks,
    [switch]$Rebuild
)

Write-Host "🚀 Starting Zabbix MCP Chatbot Stack..." -ForegroundColor Green

# Check if .env exists
if (!(Test-Path ".env")) {
    Write-Host "❌ .env file not found. Please create it with your configuration." -ForegroundColor Red
    Write-Host "   See .env.example for template" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
if (!$SkipChecks) {
    try {
        docker info | Out-Null
    }
    catch {
        Write-Host "❌ Docker is not running. Please start Docker first." -ForegroundColor Red
        exit 1
    }
}

Write-Host "📋 Loading environment configuration..." -ForegroundColor Cyan
$envContent = Get-Content ".env" | Where-Object { $_ -match "^[^#].*=" }
foreach ($line in $envContent) {
    $key, $value = $line -split "=", 2
    [Environment]::SetEnvironmentVariable($key, $value, "Process")
}

Write-Host "🧹 Cleaning up any existing containers..." -ForegroundColor Yellow
docker-compose down

if ($Rebuild) {
    Write-Host "📦 Building custom images (force rebuild)..." -ForegroundColor Cyan
    docker-compose build --no-cache
} else {
    Write-Host "📦 Building custom images..." -ForegroundColor Cyan
    docker-compose build
}

Write-Host "🔄 Starting infrastructure services (DB, Zabbix, Ollama)..." -ForegroundColor Cyan
docker-compose up -d db zabbix-server zabbix-web ollama

Write-Host "⏳ Waiting for Zabbix Web UI to be ready..." -ForegroundColor Yellow
$timeout = 300
$counter = 0
do {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api_jsonrpc.php" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            break
        }
    }
    catch {
        # Continue waiting
    }
    
    Write-Host "   Waiting for Zabbix Web UI... ($counter/$timeout seconds)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
    $counter += 10
} while ($counter -lt $timeout)

if ($counter -ge $timeout) {
    Write-Host "❌ Zabbix Web UI failed to start within $timeout seconds" -ForegroundColor Red
    Write-Host "📋 Check logs: docker-compose logs zabbix-web" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Zabbix Web UI is ready!" -ForegroundColor Green

Write-Host "🤖 Waiting for Ollama to be ready..." -ForegroundColor Yellow
do {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            break
        }
    }
    catch {
        Write-Host "   Waiting for Ollama..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
} while ($true)

$model = $env:OLLAMA_MODEL
if (!$model) { $model = "qwen2.5:3b-instruct" }

Write-Host "📥 Pulling Ollama model: $model" -ForegroundColor Cyan
$pullData = @{
    name = $model
} | ConvertTo-Json

try {
    Invoke-WebRequest -Uri "http://localhost:11434/api/pull" -Method POST -Body $pullData -ContentType "application/json" -UseBasicParsing | Out-Null
    Write-Host "✅ Model pulled successfully!" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Warning: Could not pull model automatically. You may need to pull it manually." -ForegroundColor Yellow
}

Write-Host "🔧 Starting MCP Server and Chatbot..." -ForegroundColor Cyan
docker-compose up -d zabbix-mcp chatbot

Write-Host "⏳ Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "🔧 Starting remaining services..." -ForegroundColor Cyan
docker-compose up -d

Write-Host "✅ All services started!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "  - Zabbix Web UI: http://localhost:8080 (Admin/zabbix)" -ForegroundColor White
Write-Host "  - Chatbot: http://localhost:9000" -ForegroundColor White
Write-Host "  - Open WebUI: http://localhost:3000" -ForegroundColor White
Write-Host "  - MCP Server: http://localhost:8000" -ForegroundColor White
Write-Host "  - Ollama API: http://localhost:11434" -ForegroundColor White
Write-Host ""
Write-Host "📊 Check status with: docker-compose ps" -ForegroundColor Yellow
Write-Host "📋 Check logs with: docker-compose logs -f [service-name]" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎉 Complete stack is now running!" -ForegroundColor Green
