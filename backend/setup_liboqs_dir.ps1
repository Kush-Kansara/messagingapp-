# Quick setup script for LIBOQS_DIR environment variable
# This helps you set LIBOQS_DIR whether liboqs is already built or needs to be built

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LIBOQS_DIR Setup Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if LIBOQS_DIR is already set
if ($env:LIBOQS_DIR) {
    Write-Host "[INFO] LIBOQS_DIR is already set to: $env:LIBOQS_DIR" -ForegroundColor Yellow
    if (Test-Path $env:LIBOQS_DIR) {
        Write-Host "[OK] Path exists and is valid" -ForegroundColor Green
        Write-Host ""
        Write-Host "You're all set! You can proceed with the next steps." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[WARNING] Path does not exist. You may need to update it." -ForegroundColor Yellow
    }
}

Write-Host "LIBOQS_DIR is not set or invalid." -ForegroundColor Yellow
Write-Host ""
Write-Host "Choose an option:" -ForegroundColor Cyan
Write-Host "1. I already have liboqs built somewhere (I'll provide the path)" -ForegroundColor White
Write-Host "2. I need to clone and build liboqs from scratch" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Enter choice (1 or 2)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Enter the path to your liboqs BUILD directory." -ForegroundColor Cyan
    Write-Host "This should be the 'build' folder inside your liboqs source directory." -ForegroundColor Gray
    Write-Host "Example: C:\liboqs\build or C:\Users\YourName\liboqs\build" -ForegroundColor Gray
    Write-Host ""
    $liboqsPath = Read-Host "Enter liboqs build directory path"
    
    if (-not $liboqsPath) {
        Write-Host "[ERROR] No path provided" -ForegroundColor Red
        exit 1
    }
    
    # Normalize path
    $liboqsPath = $liboqsPath.Trim('"').Trim("'")
    
    if (-not (Test-Path $liboqsPath)) {
        Write-Host "[ERROR] Path does not exist: $liboqsPath" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please check the path and try again." -ForegroundColor Yellow
        Write-Host "The path should point to the 'build' directory inside liboqs." -ForegroundColor Yellow
        exit 1
    }
    
    # Check if it looks like a build directory
    $dllPath = Join-Path $liboqsPath "bin\Release\oqs.dll"
    if (-not (Test-Path $dllPath)) {
        $dllPath = Join-Path $liboqsPath "bin\oqs.dll"
        if (-not (Test-Path $dllPath)) {
            Write-Host "[WARNING] Could not find oqs.dll in expected location" -ForegroundColor Yellow
            Write-Host "Expected locations:" -ForegroundColor Yellow
            Write-Host "  - $($liboqsPath)\bin\Release\oqs.dll" -ForegroundColor Gray
            Write-Host "  - $($liboqsPath)\bin\oqs.dll" -ForegroundColor Gray
            Write-Host ""
            $continue = Read-Host "Continue anyway? (y/n)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                exit 1
            }
        }
    }
    
    # Set environment variable for current session
    $env:LIBOQS_DIR = $liboqsPath
    Write-Host ""
    Write-Host "[OK] Set LIBOQS_DIR = $liboqsPath (current session)" -ForegroundColor Green
    
    # Ask about permanent setting
    Write-Host ""
    $setPermanent = Read-Host "Set LIBOQS_DIR permanently? (y/n)"
    if ($setPermanent -eq "y" -or $setPermanent -eq "Y") {
        try {
            [System.Environment]::SetEnvironmentVariable("LIBOQS_DIR", $liboqsPath, "User")
            Write-Host "[OK] Set LIBOQS_DIR permanently (User variable)" -ForegroundColor Green
            Write-Host "Note: You may need to restart your terminal for this to take effect" -ForegroundColor Yellow
        } catch {
            Write-Host "[ERROR] Could not set permanent variable: $_" -ForegroundColor Red
            Write-Host "You can set it manually:" -ForegroundColor Yellow
            Write-Host "1. Open System Properties > Environment Variables" -ForegroundColor Yellow
            Write-Host "2. Add User variable: LIBOQS_DIR = $liboqsPath" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS! LIBOQS_DIR is now set" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verify with: echo `$env:LIBOQS_DIR" -ForegroundColor Cyan
    Write-Host ""
    
} elseif ($choice -eq "2") {
    Write-Host ""
    Write-Host "You need to build liboqs first." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Steps to build liboqs:" -ForegroundColor Yellow
    Write-Host "1. Clone liboqs repository:" -ForegroundColor White
    Write-Host "   git clone https://github.com/open-quantum-safe/liboqs.git" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Build liboqs with CMake:" -ForegroundColor White
    Write-Host "   cd liboqs" -ForegroundColor Gray
    Write-Host "   mkdir build" -ForegroundColor Gray
    Write-Host "   cd build" -ForegroundColor Gray
    Write-Host "   cmake .. -G `"Visual Studio 17 2022`" -A x64 -DCMAKE_BUILD_TYPE=Release" -ForegroundColor Gray
    Write-Host "   cmake --build . --config Release" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. After building, run this script again and choose option 1" -ForegroundColor White
    Write-Host "   Or set LIBOQS_DIR manually:" -ForegroundColor White
    Write-Host "   `$env:LIBOQS_DIR = `"C:\path\to\liboqs\build`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor Yellow
    Write-Host "- CMake (https://cmake.org/download/)" -ForegroundColor White
    Write-Host "- Visual Studio Build Tools or Visual Studio with C++ support" -ForegroundColor White
    Write-Host "- Git (https://git-scm.com/download/win)" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: Building liboqs can take 10-30 minutes." -ForegroundColor Yellow
    Write-Host ""
    
} else {
    Write-Host "[ERROR] Invalid choice" -ForegroundColor Red
    exit 1
}




