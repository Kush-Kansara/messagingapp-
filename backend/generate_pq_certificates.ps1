# Generate Post-Quantum Certificates using OQS-OpenSSL
# This script generates TLS certificates with post-quantum signature algorithms

param(
    [string]$ProviderPath = "",
    [string]$OpenSSLPath = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
    [string]$OutputDir = "certs",
    [string]$SignatureAlg = "dilithium2",
    [int]$Days = 365
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Post-Quantum Certificate Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for OpenSSL
if (-not (Test-Path $OpenSSLPath)) {
    Write-Host "[ERROR] OpenSSL not found at: $OpenSSLPath" -ForegroundColor Red
    Write-Host "Please install OpenSSL 3.x or provide the path" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Using OpenSSL: $OpenSSLPath" -ForegroundColor Green

# Check for provider and find DLL
$providerDir = $null
$providerDll = $null

if ($ProviderPath) {
    # Resolve to absolute path
    if (Test-Path $ProviderPath) {
        $resolvedPath = Resolve-Path $ProviderPath
        if ($resolvedPath -is [Array]) {
            $resolvedPath = $resolvedPath[0]
        }
        
        # Check if it's a directory or file
        if ((Get-Item $resolvedPath) -is [System.IO.DirectoryInfo]) {
            $providerDir = $resolvedPath.Path
            # Look for DLL in this directory
            $dllFiles = @("oqsprovider.dll", "oqsprov.dll")
            foreach ($dllName in $dllFiles) {
                $dllPath = Join-Path $providerDir $dllName
                if (Test-Path $dllPath) {
                    $providerDll = $dllPath
                    break
                }
            }
        } else {
            # It's a file, get the directory
            $providerDir = (Get-Item $resolvedPath).DirectoryName
            $providerDll = $resolvedPath.Path
        }
    }
}

# If provider path not found, try default locations
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
                    $providerDll = $dllPath
                    break
                }
            }
            if ($providerDll) { break }
        }
    }
}

# Set provider arguments for OpenSSL
$providerArgs = @()
if ($providerDir) {
    $env:OPENSSL_MODULES = $providerDir
    
    # Ensure oqs.dll is available (required dependency for oqsprovider.dll)
    $oqsDllPath = Join-Path $providerDir "oqs.dll"
    if (-not (Test-Path $oqsDllPath)) {
        Write-Host "[INFO] Looking for oqs.dll dependency..." -ForegroundColor Cyan
        # Try to find oqs.dll from liboqs
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
        } else {
            Write-Host "[WARNING] oqs.dll not found. Provider may fail to load." -ForegroundColor Yellow
            Write-Host "Please ensure liboqs is built and oqs.dll is available." -ForegroundColor Yellow
        }
    }
    
    # Add provider directory to PATH so Windows can find DLL dependencies
    $env:PATH = "$providerDir;$env:PATH"
    
    $providerArgs = @("-provider-path", $providerDir, "-provider", "default", "-provider", "oqsprovider")
    Write-Host "[OK] Using provider from: $providerDir" -ForegroundColor Green
    Write-Host "[OK] Provider DLL: $providerDll" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Provider path not found" -ForegroundColor Yellow
    Write-Host "Certificates will use classical algorithms only" -ForegroundColor Yellow
    if ($ProviderPath) {
        Write-Host "Searched in: $ProviderPath" -ForegroundColor Yellow
    }
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "[OK] Created output directory: $OutputDir" -ForegroundColor Green
}

$certPath = Resolve-Path $OutputDir

Write-Host ""
Write-Host "Generating post-quantum certificate..." -ForegroundColor Cyan
Write-Host "Signature algorithm: $SignatureAlg" -ForegroundColor Cyan
Write-Host ""

# Check if algorithm is available
Write-Host "Checking for $SignatureAlg algorithm..." -ForegroundColor Yellow
$algCheckArgs = @("list", "-signature-algorithms") + $providerArgs
$algCheck = & $OpenSSLPath $algCheckArgs 2>&1 | Select-String -Pattern $SignatureAlg

if (-not $algCheck -and $providerDir) {
    Write-Host "[WARNING] Algorithm $SignatureAlg not found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available post-quantum signature algorithms:" -ForegroundColor Cyan
    $availableAlgs = & $OpenSSLPath $algCheckArgs 2>&1 | Select-String -Pattern "falcon|sphincs|dilithium" | Select-Object -First 10
    if ($availableAlgs) {
        $availableAlgs | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } else {
        Write-Host "  (No common PQ algorithms found)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Suggest alternatives based on requested algorithm
    if ($SignatureAlg -match "dilithium") {
        Write-Host "[INFO] Dilithium algorithms may not be enabled in this liboqs build." -ForegroundColor Yellow
        Write-Host "[INFO] Suggested alternatives: falcon512, falcon1024, or sphincssha2128fsimple" -ForegroundColor Cyan
        Write-Host ""
        $useAlternative = Read-Host "Use falcon512 instead? (y/n)"
        if ($useAlternative -eq "y" -or $useAlternative -eq "Y") {
            $SignatureAlg = "falcon512"
            Write-Host "[OK] Using falcon512 instead" -ForegroundColor Green
        } else {
            Write-Host "Falling back to RSA..." -ForegroundColor Yellow
            $SignatureAlg = "rsa:4096"
            $providerArgs = @()  # Don't use provider for RSA
        }
    } else {
        Write-Host "Falling back to RSA..." -ForegroundColor Yellow
        $SignatureAlg = "rsa:4096"
        $providerArgs = @()  # Don't use provider for RSA
    }
}

# Generate private key
Write-Host "Step 1: Generating private key..." -ForegroundColor Cyan
$keyFile = Join-Path $certPath "server.key"

try {
    $genpkeyArgs = @("genpkey", "-algorithm", $SignatureAlg, "-out", $keyFile) + $providerArgs
    & $OpenSSLPath $genpkeyArgs 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Private key generated: $keyFile" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to generate private key" -ForegroundColor Red
        $errorOutput = & $OpenSSLPath $genpkeyArgs 2>&1
        Write-Host $errorOutput -ForegroundColor Red
        Write-Host "Trying with RSA fallback..." -ForegroundColor Yellow
        & $OpenSSLPath genrsa -out $keyFile 4096 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] RSA private key generated" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to generate key" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "[ERROR] Exception: $_" -ForegroundColor Red
    exit 1
}

# Generate certificate signing request
Write-Host ""
Write-Host "Step 2: Generating certificate signing request..." -ForegroundColor Cyan
$csrFile = Join-Path $certPath "server.csr"

$reqCmd = @($OpenSSLPath, "req", "-new", "-key", $keyFile, "-out", $csrFile, "-subj", "/CN=localhost/O=Post-Quantum Document Server/C=US") + $providerArgs
& $reqCmd[0] $reqCmd[1..($reqCmd.Length-1)] 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] CSR generated: $csrFile" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to generate CSR" -ForegroundColor Red
    exit 1
}

# Generate self-signed certificate
Write-Host ""
Write-Host "Step 3: Generating self-signed certificate..." -ForegroundColor Cyan
$certFile = Join-Path $certPath "server.crt"

$x509Cmd = @($OpenSSLPath, "x509", "-req", "-in", $csrFile, "-signkey", $keyFile, "-out", $certFile, "-days", $Days.ToString(), "-extensions", "v3_req", "-extfile", (Join-Path $PSScriptRoot "cert_extensions.cnf")) + $providerArgs
& $x509Cmd[0] $x509Cmd[1..($x509Cmd.Length-1)] 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    # Try without extensions
    Write-Host "[WARNING] Failed with extensions, trying without..." -ForegroundColor Yellow
    $x509Cmd = @($OpenSSLPath, "x509", "-req", "-in", $csrFile, "-signkey", $keyFile, "-out", $certFile, "-days", $Days.ToString()) + $providerArgs
    & $x509Cmd[0] $x509Cmd[1..($x509Cmd.Length-1)] 2>&1 | Out-Null
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Certificate generated: $certFile" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to generate certificate" -ForegroundColor Red
    exit 1
}

# Display certificate info
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Certificate Generated Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Certificate details:" -ForegroundColor Cyan
& $OpenSSLPath x509 -in $certFile -text -noout | Select-String -Pattern "Subject:|Issuer:|Signature Algorithm:|Not Before|Not After"

Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  Private key: $keyFile" -ForegroundColor Yellow
Write-Host "  Certificate: $certFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Configure server to use these certificates" -ForegroundColor Yellow
Write-Host "2. Update .env file with certificate paths" -ForegroundColor Yellow
Write-Host "3. Start server with HTTPS enabled" -ForegroundColor Yellow

