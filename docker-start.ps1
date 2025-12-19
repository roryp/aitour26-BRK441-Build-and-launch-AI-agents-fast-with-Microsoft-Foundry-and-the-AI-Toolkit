# ===================================================================
# Docker Startup Script for Windows
# ===================================================================
# This script starts the full Zava AI Tour stack with proper
# environment variable handling for Windows
# ===================================================================

param(
    [switch]$Build,
    [switch]$Detached,
    [switch]$Clean
)

Write-Host "🚀 Zava AI Tour 26 - Docker Startup" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Check if Docker is running
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker is running" -ForegroundColor Green

# Check Azure CLI login
$azAccount = az account show 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not $azAccount) {
    Write-Host "⚠️  Not logged into Azure CLI. Running 'az login'..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Azure login failed" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ Logged into Azure as: $($azAccount.user.name)" -ForegroundColor Green

# Get Azure access token for AI Foundry
Write-Host "🔑 Getting Azure access token..." -ForegroundColor Cyan
$token = az account get-access-token --resource "https://ai.azure.com" --query "accessToken" -o tsv 2>&1
if ($LASTEXITCODE -eq 0 -and $token) {
    $env:AZURE_ACCESS_TOKEN = $token
    Write-Host "✅ Access token obtained (valid for ~1 hour)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not get access token. Will try DefaultAzureCredential in container." -ForegroundColor Yellow
}

# Set environment variables for docker-compose
$env:USERPROFILE = $env:USERPROFILE  # Ensure it's set

# Check if .env file exists
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.docker") {
        Write-Host "📋 Creating .env from .env.docker template..." -ForegroundColor Yellow
        Copy-Item ".env.docker" ".env"
        Write-Host "⚠️  Please edit .env with your Azure AI Foundry settings!" -ForegroundColor Yellow
    } elseif (Test-Path "src/python/workshop/.env") {
        Write-Host "📋 Copying environment from src/python/workshop/.env..." -ForegroundColor Yellow
        Copy-Item "src/python/workshop/.env" ".env"
    } else {
        Write-Host "❌ No .env file found. Please create one from .env.docker template." -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ Environment file found" -ForegroundColor Green

# Clean start if requested
if ($Clean) {
    Write-Host "🧹 Cleaning up existing containers and volumes..." -ForegroundColor Yellow
    docker compose -f docker-compose.full.yml down -v
}

# Build and run
$composeArgs = @("-f", "docker-compose.full.yml", "up")

if ($Build) {
    $composeArgs += "--build"
}

if ($Detached) {
    $composeArgs += "-d"
}

Write-Host ""
Write-Host "🐳 Starting Docker Compose..." -ForegroundColor Cyan
Write-Host "   Command: docker compose $($composeArgs -join ' ')" -ForegroundColor Gray
Write-Host ""

docker compose @composeArgs

if ($Detached -and $LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Services started in background" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Check status:  docker compose -f docker-compose.full.yml ps" -ForegroundColor Cyan
    Write-Host "📋 View logs:     docker compose -f docker-compose.full.yml logs -f" -ForegroundColor Cyan
    Write-Host "🌐 Open app:      http://localhost:8000" -ForegroundColor Cyan
    Write-Host "🛑 Stop:          docker compose -f docker-compose.full.yml down" -ForegroundColor Cyan
}
