# Build script for liboqs on Windows
# This will help you build liboqs from source

$liboqsPath = "C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "liboqs Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if path exists
if (-not (Test-Path $liboqsPath)) {
    Write-Host "ERROR: Path does not exist: $liboqsPath" -ForegroundColor Red
    exit 1
}

Write-Host "liboqs source path: $liboqsPath" -ForegroundColor Green
Write-Host ""

# Check for CMake
Write-Host "Checking for CMake..." -ForegroundColor Yellow
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if ($cmake) {
    Write-Host "[OK] CMake found: $($cmake.Path)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] CMake not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install CMake:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://cmake.org/download/" -ForegroundColor Yellow
    Write-Host "2. Install it and add to PATH" -ForegroundColor Yellow
    Write-Host "3. Restart this terminal and try again" -ForegroundColor Yellow
    exit 1
}

# Check for Visual Studio
Write-Host ""
Write-Host "Checking for Visual Studio Build Tools..." -ForegroundColor Yellow
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsVersion = & $vsWhere -latest -property installationVersion
    Write-Host "[OK] Visual Studio found: $vsVersion" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Visual Studio may not be installed" -ForegroundColor Yellow
    Write-Host "You may need Visual Studio Build Tools" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building liboqs..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This may take 10-30 minutes depending on your computer" -ForegroundColor Yellow
Write-Host ""

# Create build directory
$buildPath = Join-Path $liboqsPath "build"
if (Test-Path $buildPath) {
    Write-Host "Build directory already exists, cleaning..." -ForegroundColor Yellow
    Remove-Item $buildPath -Recurse -Force
}
New-Item -ItemType Directory -Path $buildPath | Out-Null

# Change to build directory
Push-Location $buildPath

try {
    Write-Host "Step 1: Configuring with CMake..." -ForegroundColor Cyan
    
    # Try to find Visual Studio generator
    $generator = "Visual Studio 17 2022"
    $cmakeArgs = @(
        "..",
        "-G", $generator,
        "-A", "x64",
        "-DCMAKE_BUILD_TYPE=Release"
    )
    
    Write-Host "Running: cmake $($cmakeArgs -join ' ')" -ForegroundColor Gray
    & cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] CMake configuration failed!" -ForegroundColor Red
        Write-Host "Trying alternative generator..." -ForegroundColor Yellow
        
        # Try MinGW if available
        $cmakeArgs = @(
            "..",
            "-G", "MinGW Makefiles",
            "-DCMAKE_BUILD_TYPE=Release"
        )
        & cmake @cmakeArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] CMake configuration failed with all generators" -ForegroundColor Red
            Write-Host "You may need to install Visual Studio Build Tools" -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "[OK] CMake configuration successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Step 2: Building liboqs (this will take a while)..." -ForegroundColor Cyan
    
    & cmake --build . --config Release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Build failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "[SUCCESS] liboqs built successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Check for output files
    $dllPath = Join-Path $buildPath "bin\Release\oqs.dll"
    if (Test-Path $dllPath) {
        Write-Host "Built library found at: $dllPath" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Setting up environment..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Set environment variable
    $env:LIBOQS_DIR = $buildPath
    Write-Host "[OK] Set LIBOQS_DIR = $buildPath (current session)" -ForegroundColor Green
    
    # Ask about permanent setting
    $setPermanent = Read-Host "Set LIBOQS_DIR permanently? (y/n)"
    if ($setPermanent -eq "y" -or $setPermanent -eq "Y") {
        [System.Environment]::SetEnvironmentVariable("LIBOQS_DIR", $buildPath, "User")
        Write-Host "[OK] Set LIBOQS_DIR permanently" -ForegroundColor Green
        Write-Host "Restart your terminal for it to take effect" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS! liboqs is ready to use" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart your terminal (if you set it permanently)" -ForegroundColor Yellow
    Write-Host "2. Activate your venv: .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    Write-Host "3. Test: python verify_pq.py" -ForegroundColor Yellow
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Build failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
