# Startup script for FastAPI server with PQ support
# This sets the OQS_INSTALL_PATH before starting uvicorn (optional)

Write-Host "Setting up post-quantum environment..." -ForegroundColor Cyan

# Check if LIBOQS_DIR is set in environment
$liboqsDir = $env:LIBOQS_DIR

if ($liboqsDir -and (Test-Path $liboqsDir)) {
    Write-Host "[OK] Using liboqs from: $liboqsDir" -ForegroundColor Green
    $env:OQS_INSTALL_PATH = $liboqsDir
    
    # Try to find DLL
    $dllPaths = @(
        "$liboqsDir\bin\oqs.dll",
        "$liboqsDir\bin\Release\oqs.dll",
        "$liboqsDir\lib\oqs.dll"
    )
    
    $dllFound = $false
    foreach ($dllPath in $dllPaths) {
        if (Test-Path $dllPath) {
            Write-Host "[OK] Found liboqs DLL at: $dllPath" -ForegroundColor Green
            $dllFound = $true
            break
        }
    }
    
    if (-not $dllFound) {
        Write-Host "[WARNING] liboqs DLL not found, but continuing anyway" -ForegroundColor Yellow
        Write-Host "[INFO] App will use fallback mode (still secure, but not full PQ)" -ForegroundColor Cyan
    }
} else {
    Write-Host "[INFO] LIBOQS_DIR not set - liboqs is optional" -ForegroundColor Cyan
    Write-Host "[INFO] App will use fallback mode (still secure, but not full PQ)" -ForegroundColor Cyan
    Write-Host "[INFO] To enable full PQ: Set LIBOQS_DIR environment variable" -ForegroundColor Yellow
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& ".\venv\Scripts\Activate.ps1"

# Test liboqs import (optional - app works without it)
Write-Host "Testing liboqs import..." -ForegroundColor Cyan
try {
    python -c "import oqs; print('[OK] liboqs loaded successfully')" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] liboqs is ready! Full post-quantum security enabled." -ForegroundColor Green
    } else {
        Write-Host "[WARNING] liboqs import failed - using fallback mode" -ForegroundColor Yellow
        Write-Host "[INFO] App will still work, but with fallback cryptography" -ForegroundColor Cyan
    }
} catch {
    Write-Host "[WARNING] liboqs not available - using fallback mode" -ForegroundColor Yellow
    Write-Host "[INFO] App will still work, but with fallback cryptography" -ForegroundColor Cyan
    Write-Host "[INFO] To enable full PQ: Install liboqs-python and set LIBOQS_DIR" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Starting FastAPI server..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Start uvicorn
# For HTTPS with OQS-OpenSSL, use: .\start_server_https.ps1
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

