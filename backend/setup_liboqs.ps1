# Setup script for liboqs on Windows
# Run this script to help set up liboqs

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "liboqs Setup Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ask user where liboqs is located
$liboqsPath = Read-Host "Enter the full path where you extracted liboqs (e.g., C:\liboqs or C:\Users\xxcbj\liboqs)"

# Check if path exists
if (-not (Test-Path $liboqsPath)) {
    Write-Host "ERROR: Path does not exist: $liboqsPath" -ForegroundColor Red
    Write-Host "Please check the path and try again." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Checking liboqs directory..." -ForegroundColor Yellow

# Check if it's a build directory or source directory
$buildPath = Join-Path $liboqsPath "build"
$binPath = Join-Path $liboqsPath "bin"
$srcPath = Join-Path $liboqsPath "src"

# Determine the correct path
$finalPath = $liboqsPath

if (Test-Path $buildPath) {
    $releasePath = Join-Path $buildPath "bin\Release"
    if (Test-Path $releasePath) {
        $finalPath = $buildPath
        Write-Host "Found build directory with Release binaries" -ForegroundColor Green
    } else {
        Write-Host "Found build directory, but no Release binaries yet" -ForegroundColor Yellow
        Write-Host "You may need to build liboqs first" -ForegroundColor Yellow
    }
} elseif (Test-Path $binPath) {
    $finalPath = $liboqsPath
    Write-Host "Found bin directory" -ForegroundColor Green
} elseif (Test-Path $srcPath) {
    Write-Host "Found source code directory" -ForegroundColor Yellow
    Write-Host "You need to build liboqs first. See SETUP_LIBOQS.md for instructions" -ForegroundColor Yellow
    $finalPath = $liboqsPath
} else {
    Write-Host "Warning: Could not determine liboqs structure" -ForegroundColor Yellow
    Write-Host "Using path as-is: $liboqsPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setting LIBOQS_DIR to: $finalPath" -ForegroundColor Cyan

# Set environment variable for current session
$env:LIBOQS_DIR = $finalPath
Write-Host "[OK] Set LIBOQS_DIR for current session" -ForegroundColor Green

# Ask if user wants to set it permanently
Write-Host ""
$setPermanent = Read-Host "Do you want to set LIBOQS_DIR permanently? (y/n)"

if ($setPermanent -eq "y" -or $setPermanent -eq "Y") {
    try {
        [System.Environment]::SetEnvironmentVariable("LIBOQS_DIR", $finalPath, "User")
        Write-Host "[OK] Set LIBOQS_DIR permanently (User variable)" -ForegroundColor Green
        Write-Host "Note: You may need to restart your terminal for this to take effect" -ForegroundColor Yellow
    } catch {
        Write-Host "ERROR: Could not set permanent variable: $_" -ForegroundColor Red
        Write-Host "You can set it manually:" -ForegroundColor Yellow
        Write-Host "1. Open System Properties > Environment Variables" -ForegroundColor Yellow
        Write-Host "2. Add User variable: LIBOQS_DIR = $finalPath" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing liboqs..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test if it works
try {
    python -c "import oqs; kem = oqs.KeyEncapsulation('Kyber512'); pub = kem.generate_keypair(); print('[SUCCESS] liboqs is working! Public key:', len(pub), 'bytes')"
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "SUCCESS! liboqs is working correctly!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now run: python verify_pq.py" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "ERROR: liboqs test failed" -ForegroundColor Red
        Write-Host "Check the error message above" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Could not test liboqs: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure you're in the backend directory with venv activated" -ForegroundColor Yellow
    Write-Host "2. Check that liboqs DLL files exist in the path" -ForegroundColor Yellow
    Write-Host "3. See SETUP_LIBOQS.md for more help" -ForegroundColor Yellow
}

