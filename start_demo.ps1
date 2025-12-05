# Quick demo start script
# This script helps you quickly start both backend and frontend for a demo

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Post-Quantum Messaging App - Demo Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if MongoDB is running
Write-Host "Checking MongoDB..." -ForegroundColor Yellow
$mongoService = Get-Service MongoDB -ErrorAction SilentlyContinue
if ($mongoService -and $mongoService.Status -eq "Running") {
    Write-Host "[OK] MongoDB is running" -ForegroundColor Green
} else {
    Write-Host "[WARNING] MongoDB service not found or not running" -ForegroundColor Yellow
    Write-Host "  Attempting to start MongoDB..." -ForegroundColor Yellow
    try {
        Start-Service MongoDB -ErrorAction Stop
        Write-Host "[OK] MongoDB started successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Could not start MongoDB. Please start it manually." -ForegroundColor Red
        Write-Host "  Try: Start-Service MongoDB" -ForegroundColor Yellow
        Write-Host "  Or check if MongoDB is installed and running" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Cyan
Write-Host ""

# Start backend in a new window
Write-Host "[1/2] Starting backend server..." -ForegroundColor Yellow
$backendScript = Join-Path $PSScriptRoot "backend\start_server.ps1"
if (Test-Path $backendScript) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\backend'; .\start_server.ps1"
    Write-Host "[OK] Backend starting in new window" -ForegroundColor Green
    Start-Sleep -Seconds 3
} else {
    Write-Host "[ERROR] Backend start script not found at: $backendScript" -ForegroundColor Red
}

# Start frontend in a new window
Write-Host "[2/2] Starting frontend server..." -ForegroundColor Yellow
$frontendDir = Join-Path $PSScriptRoot "frontend"
if (Test-Path $frontendDir) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$frontendDir'; npm run dev"
    Write-Host "[OK] Frontend starting in new window" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Frontend directory not found at: $frontendDir" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Demo Services Starting..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend:  http://localhost:8000" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:5173" -ForegroundColor Cyan
Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wait a few seconds for services to start, then:" -ForegroundColor Yellow
Write-Host "  1. Open http://localhost:5173 in your browser" -ForegroundColor White
Write-Host "  2. Register or login with demo users" -ForegroundColor White
Write-Host ""
Write-Host "For demo setup, run: cd backend && python setup_demo.py" -ForegroundColor Yellow
Write-Host "For demo guide, see: DEMO_GUIDE.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit this window (services will keep running)..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


