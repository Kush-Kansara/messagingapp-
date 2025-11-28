# Setup script for OQS-OpenSSL Provider on Windows
# This script helps build and configure oqs-provider for use with OpenSSL 3

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OQS-OpenSSL Provider Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script helps you set up oqs-provider for post-quantum TLS/HTTPS" -ForegroundColor Yellow
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# Check for Git
try {
    $gitVersion = git --version 2>&1
    Write-Host "[OK] Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Git not found. Please install Git first." -ForegroundColor Red
    Write-Host "Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Check for CMake
try {
    $cmakeVersion = cmake --version 2>&1 | Select-Object -First 1
    Write-Host "[OK] CMake found: $cmakeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] CMake not found. Please install CMake first." -ForegroundColor Red
    Write-Host "Download from: https://cmake.org/download/" -ForegroundColor Yellow
    exit 1
}

# Check for Visual Studio Build Tools or MSVC
Write-Host ""
Write-Host "Checking for C++ compiler..." -ForegroundColor Cyan
try {
    $clVersion = cl 2>&1 | Select-Object -First 1
    Write-Host "[OK] MSVC compiler found" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] MSVC compiler not found in PATH" -ForegroundColor Yellow
    Write-Host "You may need to run this from 'Developer Command Prompt for VS'" -ForegroundColor Yellow
    Write-Host "Or install Visual Studio Build Tools" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1: Clone oqs-provider repository" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$oqsProviderPath = Join-Path $PSScriptRoot "..\oqs-provider"
$resolvedPath = Resolve-Path $oqsProviderPath -ErrorAction SilentlyContinue
if ($resolvedPath) {
    # Resolve-Path returns PathInfo object(s), extract the path string
    if ($resolvedPath -is [Array]) {
        $oqsProviderPath = [string]$resolvedPath[0].Path
    } else {
        $oqsProviderPath = [string]$resolvedPath.Path
    }
}

if (-not $oqsProviderPath -or -not (Test-Path $oqsProviderPath)) {
    Write-Host "oqs-provider not found. Cloning repository..." -ForegroundColor Yellow
    $parentDir = Split-Path $PSScriptRoot -Parent
    $clonePath = Join-Path $parentDir "oqs-provider"
    
    Write-Host "Cloning to: $clonePath" -ForegroundColor Cyan
    git clone https://github.com/open-quantum-safe/oqs-provider.git $clonePath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to clone oqs-provider repository" -ForegroundColor Red
        exit 1
    }
    
    $oqsProviderPath = $clonePath
    Write-Host "[OK] Repository cloned successfully" -ForegroundColor Green
} else {
    Write-Host "[OK] oqs-provider found at: $oqsProviderPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: Check for OpenSSL 3" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for OpenSSL 3
$opensslPath = $null
$possiblePaths = @(
    "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
    "C:\OpenSSL-Win64\bin\openssl.exe",
    "C:\Program Files (x86)\OpenSSL-Win64\bin\openssl.exe",
    "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $opensslPath = $path
        break
    }
}

if ($opensslPath) {
    Write-Host "[OK] OpenSSL found at: $opensslPath" -ForegroundColor Green
    $opensslVersion = & $opensslPath version
    Write-Host "Version: $opensslVersion" -ForegroundColor Cyan
    
    if ($opensslVersion -notmatch "OpenSSL 3\.[0-9]") {
        Write-Host "[WARNING] OpenSSL 3.x is required. Found: $opensslVersion" -ForegroundColor Yellow
        Write-Host "Please install OpenSSL 3.x from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] OpenSSL not found in standard locations" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install OpenSSL 3.x:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
    Write-Host "2. Install to default location (C:\Program Files\OpenSSL-Win64)" -ForegroundColor Yellow
    Write-Host "3. Or provide the path manually" -ForegroundColor Yellow
    Write-Host ""
    $customPath = Read-Host "Enter OpenSSL path (or press Enter to skip)"
    if ($customPath -and (Test-Path $customPath)) {
        $opensslPath = $customPath
        Write-Host "[OK] Using custom OpenSSL path: $opensslPath" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Cannot proceed without OpenSSL 3" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3: Check for liboqs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for liboqs
$liboqsPath = $env:LIBOQS_DIR
$liboqsConfigDir = $null

if (-not $liboqsPath) {
    # Try to auto-detect liboqs in common locations
    $possiblePaths = @(
        Join-Path $PSScriptRoot "liboqs\build",
        Join-Path (Split-Path $PSScriptRoot -Parent) "liboqs\build"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $liboqsPath = $path
            break
        }
    }
}

if ($liboqsPath -and (Test-Path $liboqsPath)) {
    # Ensure $liboqsPath is a string, not an array
    if ($liboqsPath -is [Array]) {
        $liboqsPath = $liboqsPath[0]
    }
    
    # If the path already points to a config directory (contains liboqsConfig.cmake), use it directly
    $testConfigFile = Join-Path $liboqsPath "liboqsConfig.cmake"
    if (Test-Path $testConfigFile) {
        $liboqsConfigDir = $liboqsPath
        Write-Host "[OK] liboqs CMake config directory found at: $liboqsPath" -ForegroundColor Green
    } else {
        Write-Host "[OK] liboqs build directory found at: $liboqsPath" -ForegroundColor Green
        
        # Find the liboqsConfig.cmake file
        # CMake's find_package looks for liboqsConfig.cmake in:
        # - liboqs_DIR/liboqsConfig.cmake
        # - liboqs_DIR/lib/cmake/liboqs/liboqsConfig.cmake
        # - liboqs_DIR/src/liboqsConfig.cmake (common in build directories)
        
        $configPath1 = Join-Path $liboqsPath "liboqsConfig.cmake"
        $configPath2 = Join-Path $liboqsPath "lib\cmake\liboqs\liboqsConfig.cmake"
        $configPath3 = Join-Path $liboqsPath "src\liboqsConfig.cmake"
        
        $configPaths = @($configPath1, $configPath2, $configPath3)
        
        foreach ($configPath in $configPaths) {
            if (Test-Path $configPath) {
                $liboqsConfigDir = Split-Path $configPath -Parent
                Write-Host "[OK] Found liboqs CMake config at: $configPath" -ForegroundColor Green
                break
            }
        }
        
        if (-not $liboqsConfigDir) {
            # Search recursively for the config file
            $configFile = Get-ChildItem -Path $liboqsPath -Recurse -Filter "liboqsConfig.cmake" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($configFile) {
                $liboqsConfigDir = Split-Path $configFile.FullName -Parent
                Write-Host "[OK] Found liboqs CMake config at: $($configFile.FullName)" -ForegroundColor Green
            }
        }
    }
    
    # Check if we found the config directory
    if (-not $liboqsConfigDir) {
        Write-Host "[ERROR] Could not find liboqsConfig.cmake in liboqs build directory" -ForegroundColor Red
        Write-Host "Please ensure liboqs has been built successfully" -ForegroundColor Yellow
        exit 1
    }
    
    # Fix the include directory in liboqsTargets.cmake if it points to the wrong location
    $liboqsTargetsFile = Join-Path $liboqsConfigDir "liboqsTargets.cmake"
    $liboqsBuildDir = Split-Path $liboqsConfigDir -Parent
    $correctIncludeDir = Join-Path $liboqsBuildDir "include"
    
    if ((Test-Path $liboqsTargetsFile) -and (Test-Path $correctIncludeDir)) {
        $targetsContent = Get-Content $liboqsTargetsFile -Raw
        $wrongPath = Join-Path (Split-Path $liboqsBuildDir -Parent) "src"
        
        # Convert paths to forward slashes for CMake (CMake prefers forward slashes)
        $correctIncludeDirCMake = $correctIncludeDir -replace '\\', '/'
        $wrongPathCMake = $wrongPath -replace '\\', '/'
        
        # Check if the file has the wrong include directory
        if ($targetsContent -match [regex]::Escape($wrongPathCMake)) {
            Write-Host "[INFO] Fixing liboqs include directory in CMake config..." -ForegroundColor Cyan
            $targetsContent = $targetsContent -replace [regex]::Escape($wrongPathCMake), $correctIncludeDirCMake
            Set-Content -Path $liboqsTargetsFile -Value $targetsContent -NoNewline
            Write-Host "[OK] Fixed include directory to: $correctIncludeDir" -ForegroundColor Green
        }
    }
    
    $env:LIBOQS_DIR = $liboqsConfigDir
    $liboqsPath = $liboqsConfigDir  # Update for display
} else {
    Write-Host "[ERROR] liboqs not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build liboqs first:" -ForegroundColor Yellow
    Write-Host "1. Clone: https://github.com/open-quantum-safe/liboqs" -ForegroundColor Yellow
    Write-Host "2. Build using CMake (see liboqs README)" -ForegroundColor Yellow
    Write-Host "3. Set LIBOQS_DIR environment variable or ensure liboqs is in backend\liboqs\build" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 4: Build oqs-provider" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$buildDir = Join-Path $oqsProviderPath "_build"
# Ensure $buildDir is a string
if ($buildDir -is [Array]) {
    $buildDir = [string]$buildDir[0]
} else {
    $buildDir = [string]$buildDir
}
Write-Host "Build directory: $buildDir" -ForegroundColor Cyan

# Create build directory
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Configure with CMake
Write-Host ""
Write-Host "Configuring oqs-provider with CMake..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

Push-Location $oqsProviderPath

try {
    # Get OpenSSL root directory (parent of bin)
    $opensslRoot = Split-Path (Split-Path $opensslPath -Parent) -Parent
    
    # Ensure $opensslRoot is a string, not an array
    if ($opensslRoot -is [Array]) {
        $opensslRoot = $opensslRoot[0]
    }
    $opensslRoot = [string]$opensslRoot
    
    # Get OpenSSL lib directory for modules path
    # On Windows, OpenSSL modules typically go in lib/VC/x64/MD/ossl-modules or lib/ossl-modules
    $opensslLibDir = Join-Path $opensslRoot "lib"
    $opensslModulesPath = Join-Path $opensslLibDir "ossl-modules"
    
    # Try to find the actual modules directory
    $path1 = Join-Path $opensslRoot "lib\VC\x64\MD\ossl-modules"
    $path2 = Join-Path $opensslRoot "lib\VC\x64\MDd\ossl-modules"
    $path3 = Join-Path $opensslRoot "lib\ossl-modules"
    $possibleModulePaths = @($path1, $path2, $path3, $opensslModulesPath)
    
    $actualModulesPath = $null
    foreach ($path in $possibleModulePaths) {
        $parentDir = Split-Path $path -Parent
        if (Test-Path $parentDir) {
            $actualModulesPath = $path
            break
        }
    }
    
    if (-not $actualModulesPath) {
        # Use a local directory if OpenSSL modules path can't be determined
        $actualModulesPath = Join-Path $oqsProviderPath "_build\ossl-modules"
        Write-Host "[INFO] Using local modules path: $actualModulesPath" -ForegroundColor Cyan
    }
    
    # Configure
    # Note: CMake variable is liboqs_DIR (lowercase), not LIBOQS_DIR
    # Set OPENSSL_MODULES_PATH explicitly to avoid CMake path parsing issues on Windows
    cmake -S . -B _build `
        -DCMAKE_BUILD_TYPE=Release `
        -DOPENSSL_ROOT_DIR="$opensslRoot" `
        -Dliboqs_DIR="$liboqsPath" `
        -DOPENSSL_MODULES_PATH="$actualModulesPath"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] CMake configuration failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] CMake configuration successful" -ForegroundColor Green
    
    # Build
    Write-Host ""
    Write-Host "Building oqs-provider..." -ForegroundColor Cyan
    cmake --build _build --config Release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Build successful!" -ForegroundColor Green
    
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 5: Install oqs-provider (Optional)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Install step is optional. The provider DLL is already built and can be used from the build directory." -ForegroundColor Cyan
Write-Host "[INFO] Skipping install to avoid path issues. The DLL will be located in the next step." -ForegroundColor Cyan
Write-Host ""

# Note: Install step often fails on Windows due to OpenSSL path parsing issues
# The DLL is already built and usable from the _build directory

# Find the provider library
Write-Host ""
Write-Host "Locating provider DLL..." -ForegroundColor Cyan
$providerPath = $null

# $buildDir should already be a string from earlier, but ensure it is
$buildDir = [string]$buildDir

# Search for both possible DLL names (oqsprovider.dll and oqsprov.dll)
$dllNames = @("oqsprovider.dll", "oqsprov.dll")

foreach ($dllName in $dllNames) {
    # First, try recursive search (most reliable)
    $dllFile = Get-ChildItem -Path $buildDir -Recurse -Filter $dllName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dllFile) {
        $providerPath = $dllFile.FullName
        Write-Host "[OK] Found provider DLL: $providerPath" -ForegroundColor Green
        break
    }
}

# If not found recursively, try known locations
if (-not $providerPath) {
    foreach ($dllName in $dllNames) {
        $dllPath1 = Join-Path $buildDir "bin\Release\$dllName"
        $dllPath2 = Join-Path $buildDir "bin\$dllName"
        $dllPath3 = Join-Path $buildDir "oqsprov\Release\$dllName"
        $dllPath4 = Join-Path $buildDir "oqsprov\$dllName"
        $possibleDllPaths = @($dllPath1, $dllPath2, $dllPath3, $dllPath4)
        
        foreach ($dllPath in $possibleDllPaths) {
            if (Test-Path $dllPath) {
                $providerPath = $dllPath
                Write-Host "[OK] Found provider DLL: $providerPath" -ForegroundColor Green
                break
            }
        }
        
        if ($providerPath) {
            break
        }
    }
}

if ($providerPath -and (Test-Path $providerPath)) {
    Write-Host ""
    Write-Host "[OK] Provider library found at: $providerPath" -ForegroundColor Green
    
    # Copy to a known location
    $targetDir = Join-Path $PSScriptRoot "oqs-provider"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }
    
    $dllFileName = Split-Path $providerPath -Leaf
    Copy-Item $providerPath -Destination (Join-Path $targetDir $dllFileName) -Force
    Write-Host "[OK] Provider copied to: $targetDir\$dllFileName" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can use the provider from either location:" -ForegroundColor Cyan
    Write-Host "  - Build location: $providerPath" -ForegroundColor Yellow
    Write-Host "  - Copied location: $targetDir\oqsprov.dll" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "[WARNING] Could not find provider DLL" -ForegroundColor Yellow
    Write-Host "Searching for any DLL files in build directory..." -ForegroundColor Cyan
    
    # List all DLLs found
    $allDlls = Get-ChildItem -Path $buildDir -Recurse -Filter "*.dll" -ErrorAction SilentlyContinue
    if ($allDlls) {
        Write-Host "Found the following DLL files:" -ForegroundColor Cyan
        foreach ($dll in $allDlls) {
            Write-Host "  - $($dll.FullName)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "The provider DLL might be one of these. Please check manually." -ForegroundColor Yellow
    } else {
        Write-Host "No DLL files found in: $buildDir" -ForegroundColor Yellow
        Write-Host "The build may have failed. Check the build output above." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Configure OpenSSL to use oqs-provider (see OQS_OPENSSL_SETUP.md)" -ForegroundColor Yellow
Write-Host "2. Generate certificates with post-quantum algorithms" -ForegroundColor Yellow
Write-Host "3. Configure server to use HTTPS with OQS-OpenSSL" -ForegroundColor Yellow
Write-Host ""
Write-Host "Provider location: $providerPath" -ForegroundColor Cyan
Write-Host "OpenSSL path: $opensslPath" -ForegroundColor Cyan
Write-Host "liboqs path: $liboqsPath" -ForegroundColor Cyan

