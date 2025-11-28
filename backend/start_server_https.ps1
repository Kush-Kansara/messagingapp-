# Start FastAPI server with HTTPS using OQS-OpenSSL
# This script configures the environment and starts the server with TLS

param(
    [string]$CertFile = "certs\server.crt",
    [string]$KeyFile = "certs\server.key",
    [int]$Port = 8443,
    [string]$ProviderPath = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Post-Quantum Secure Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Activate virtual environment
if (Test-Path "venv\Scripts\Activate.ps1") {
    Write-Host "Activating virtual environment..." -ForegroundColor Cyan
    & ".\venv\Scripts\Activate.ps1"
} else {
    Write-Host "[WARNING] Virtual environment not found" -ForegroundColor Yellow
}

# Check for certificates
$certPath = Join-Path $PSScriptRoot $CertFile
$keyPath = Join-Path $PSScriptRoot $KeyFile

if (-not (Test-Path $certPath)) {
    Write-Host "[ERROR] Certificate not found: $certPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "To generate certificates:" -ForegroundColor Yellow
    Write-Host "  .\generate_pq_certificates.ps1" -ForegroundColor Cyan
    exit 1
}

if (-not (Test-Path $keyPath)) {
    Write-Host "[ERROR] Private key not found: $keyPath" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Certificate: $certPath" -ForegroundColor Green
Write-Host "[OK] Private key: $keyPath" -ForegroundColor Green

# Set OQS provider path if provided
if ($ProviderPath) {
    $env:OQS_PROVIDER_PATH = $ProviderPath
    Write-Host "[OK] OQS provider path: $ProviderPath" -ForegroundColor Green
} else {
    # Try to find provider automatically
    $possiblePaths = @(
        "oqs-provider\oqsprov.dll",
        "..\oqs-provider\_build\bin\Release\oqsprov.dll"
    )
    
    foreach ($path in $possiblePaths) {
        $fullPath = Join-Path $PSScriptRoot $path
        if (Test-Path $fullPath) {
            $providerDir = Split-Path $fullPath -Parent
            $env:OPENSSL_MODULES = $providerDir
            Write-Host "[OK] Found OQS provider: $providerDir" -ForegroundColor Green
            break
        }
    }
}

# Set environment variables for the application
$env:USE_HTTPS = "true"
$env:SSL_CERTFILE = $certPath
$env:SSL_KEYFILE = $keyPath

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Starting server with HTTPS..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Server will be available at: https://localhost:$Port" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Python's ssl module uses the system OpenSSL." -ForegroundColor Yellow
Write-Host "For full OQS-OpenSSL support, use a reverse proxy (nginx) compiled with OQS-OpenSSL." -ForegroundColor Yellow
Write-Host ""

# Import oqs_ssl module to verify setup
python -c "from app.oqs_ssl import verify_oqs_openssl; verify_oqs_openssl()" 2>&1

Write-Host ""
Write-Host "Starting uvicorn server..." -ForegroundColor Cyan
Write-Host ""

# Start uvicorn with HTTPS
uvicorn app.main:app `
    --reload `
    --host 0.0.0.0 `
    --port $Port `
    --ssl-keyfile $keyPath `
    --ssl-certfile $certPath

