# Test Post-Quantum TLS Connection
# This script loads the OQS provider and tests TLS connection with post-quantum algorithms

param(
    [string]$Host = "localhost",
    [int]$Port = 8443,
    [string]$ProviderPath = "",
    [string]$OpenSSLPath = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Post-Quantum TLS Connection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for OpenSSL
if (-not (Test-Path $OpenSSLPath)) {
    Write-Host "[ERROR] OpenSSL not found at: $OpenSSLPath" -ForegroundColor Red
    Write-Host "Please install OpenSSL 3.x or provide the path" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Using OpenSSL: $OpenSSLPath" -ForegroundColor Green

# Find OQS provider
$providerDir = $null
if ($ProviderPath) {
    if (Test-Path $ProviderPath) {
        $resolvedPath = Resolve-Path $ProviderPath
        if ($resolvedPath -is [Array]) {
            $resolvedPath = $resolvedPath[0]
        }
        if ((Get-Item $resolvedPath) -is [System.IO.DirectoryInfo]) {
            $providerDir = $resolvedPath.Path
        } else {
            $providerDir = (Get-Item $resolvedPath).DirectoryName
        }
    }
}

# Try default locations
if (-not $providerDir) {
    $scriptDir = Split-Path $PSScriptRoot -Parent
    $defaultPaths = @(
        Join-Path $PSScriptRoot "oqs-provider",
        Join-Path $scriptDir "oqs-provider\_build\bin\Release",
        Join-Path $scriptDir "oqs-provider\_build\bin"
    )
    
    foreach ($path in $defaultPaths) {
        if (Test-Path $path) {
            $dllFiles = @("oqsprovider.dll", "oqsprov.dll")
            foreach ($dllName in $dllFiles) {
                $dllPath = Join-Path $path $dllName
                if (Test-Path $dllPath) {
                    $providerDir = $path
                    break
                }
            }
            if ($providerDir) { break }
        }
    }
}

if (-not $providerDir) {
    Write-Host "[WARNING] OQS provider not found" -ForegroundColor Yellow
    Write-Host "Testing with standard OpenSSL (no post-quantum support)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To enable post-quantum TLS testing:" -ForegroundColor Cyan
    Write-Host "1. Build oqs-provider: .\setup_oqs_openssl.ps1" -ForegroundColor Yellow
    Write-Host "2. Run this script again" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "[OK] Found OQS provider: $providerDir" -ForegroundColor Green
    
    # Ensure oqs.dll is available
    $oqsDllPath = Join-Path $providerDir "oqs.dll"
    if (-not (Test-Path $oqsDllPath)) {
        Write-Host "[INFO] Looking for oqs.dll dependency..." -ForegroundColor Cyan
        $liboqsPaths = @()
        if ($env:LIBOQS_DIR) {
            $liboqsPaths += $env:LIBOQS_DIR
        }
        $liboqsPaths += Join-Path $PSScriptRoot "liboqs\build\bin\Release"
        $liboqsPaths += Join-Path $PSScriptRoot "liboqs\build\bin"
        $liboqsPaths += Join-Path (Split-Path $PSScriptRoot -Parent) "liboqs\build\bin\Release"
        
        $oqsDllFound = $null
        foreach ($liboqsPath in $liboqsPaths) {
            if ($liboqsPath -and (Test-Path $liboqsPath)) {
                $testPath = Join-Path $liboqsPath "oqs.dll"
                if (Test-Path $testPath) {
                    $oqsDllFound = $testPath
                    break
                }
            }
        }
        
        if ($oqsDllFound) {
            Copy-Item $oqsDllFound -Destination $oqsDllPath -Force
            Write-Host "[OK] Copied oqs.dll to provider directory" -ForegroundColor Green
        }
    }
    
    # Set environment variables for OpenSSL
    $env:OPENSSL_MODULES = $providerDir
    $env:PATH = "$providerDir;$env:PATH"
    
    Write-Host "[OK] Provider environment configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking Available Algorithms" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# List available providers
Write-Host "Available providers:" -ForegroundColor Yellow
& $OpenSSLPath list -providers 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

Write-Host ""
Write-Host "Available KEM algorithms (post-quantum key exchange):" -ForegroundColor Yellow
$kemList = & $OpenSSLPath list -kem-algorithms 2>&1
$kyberAlgs = $kemList | Select-String -Pattern "kyber|mlkem" -CaseSensitive:$false
if ($kyberAlgs) {
    $kyberAlgs | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
} else {
    Write-Host "  (No post-quantum KEM algorithms found)" -ForegroundColor Gray
    Write-Host "  (This is normal if OQS provider is not loaded)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Available groups (TLS 1.3 key exchange groups):" -ForegroundColor Yellow
$groupsList = & $OpenSSLPath s_client -help 2>&1 | Select-String -Pattern "groups"
if ($groupsList) {
    Write-Host "  $groupsList" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing TLS Connection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Connecting to: ${Host}:${Port}" -ForegroundColor Cyan
Write-Host ""

# Try different group options
$testGroups = @(
    "kyber512",
    "x25519_kyber512_draft00",
    "X25519Kyber512Draft00",
    "MLKEM512",
    "X25519MLKEM768"
)

$connectionSuccess = $false

foreach ($group in $testGroups) {
    Write-Host "Trying group: $group" -ForegroundColor Yellow
    
    # Test connection with this group
    $testCmd = @(
        $OpenSSLPath,
        "s_client",
        "-connect", "${Host}:${Port}",
        "-groups", $group,
        "-verify_return_error"
    )
    
    $result = & $testCmd[0] $testCmd[1..($testCmd.Length-1)] 2>&1
    
    if ($LASTEXITCODE -eq 0 -or ($result -match "Verify return code: 0" -or $result -match "New, TLSv1.3")) {
        Write-Host "[OK] Connection successful with group: $group" -ForegroundColor Green
        Write-Host ""
        Write-Host "Connection details:" -ForegroundColor Cyan
        $result | Select-String -Pattern "Protocol|Cipher|Verify return code|Signature Algorithm" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        $connectionSuccess = $true
        break
    } else {
        $errorMsg = $result | Select-String -Pattern "error|failed|unsupported" -CaseSensitive:$false | Select-Object -First 1
        if ($errorMsg) {
            Write-Host "  [SKIP] $errorMsg" -ForegroundColor Gray
        }
    }
}

if (-not $connectionSuccess) {
    Write-Host ""
    Write-Host "Trying standard connection (no specific group)..." -ForegroundColor Yellow
    $testCmd = @(
        $OpenSSLPath,
        "s_client",
        "-connect", "${Host}:${Port}",
        "-verify_return_error"
    )
    
    $result = & $testCmd[0] $testCmd[1..($testCmd.Length-1)] 2>&1
    
    if ($LASTEXITCODE -eq 0 -or ($result -match "Verify return code: 0" -or $result -match "New, TLSv1.3")) {
        Write-Host "[OK] Standard TLS connection successful" -ForegroundColor Green
        Write-Host ""
        Write-Host "Connection details:" -ForegroundColor Cyan
        $result | Select-String -Pattern "Protocol|Cipher|Verify return code|Signature Algorithm" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        $connectionSuccess = $true
    } else {
        Write-Host "[ERROR] Connection failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error details:" -ForegroundColor Red
        $result | Select-String -Pattern "error|failed" -CaseSensitive:$false | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($connectionSuccess) {
    Write-Host "[OK] TLS connection test completed" -ForegroundColor Green
    if ($providerDir) {
        Write-Host "[INFO] OQS provider was loaded" -ForegroundColor Cyan
        Write-Host "[INFO] Post-quantum algorithms may be used if supported by server" -ForegroundColor Cyan
    } else {
        Write-Host "[INFO] Standard TLS connection (no post-quantum support)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] TLS connection test failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure server is running: .\start_server_https.ps1" -ForegroundColor Cyan
    Write-Host "2. Check firewall settings" -ForegroundColor Cyan
    Write-Host "3. Verify certificate is valid" -ForegroundColor Cyan
}

Write-Host ""




