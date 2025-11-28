# OQS-OpenSSL Integration Guide

This document explains how to integrate and use OQS-OpenSSL provider in this post-quantum secure document server application.

## What is OQS-OpenSSL Provider?

The **oqs-provider** (https://github.com/open-quantum-safe/oqs-provider) is an OpenSSL 3 provider that adds post-quantum cryptographic algorithms to OpenSSL. This enables TLS/HTTPS connections to use post-quantum algorithms like:

- **Key Exchange**: CRYSTALS-Kyber, BIKE, FrodoKEM, etc.
- **Signatures**: Dilithium, Falcon, SPHINCS+, etc.

## Quick Start

### 1. Build OQS-Provider

```powershell
cd backend
.\setup_oqs_openssl.ps1
```

This script will:
- Clone the oqs-provider repository
- Check for prerequisites (OpenSSL 3, liboqs, CMake)
- Build oqs-provider
- Copy the provider library to `backend/oqs-provider/`

### 2. Generate Post-Quantum Certificates

```powershell
cd backend
.\generate_pq_certificates.ps1 -ProviderPath "oqs-provider" -SignatureAlg "dilithium2"
```

This creates:
- `certs/server.key` - Private key with post-quantum signature algorithm
- `certs/server.crt` - Self-signed certificate

### 3. Start Server with HTTPS

```powershell
cd backend
.\start_server_https.ps1
```

The server will start on `https://localhost:8443` with TLS enabled.

## Architecture

### Current Implementation

The application currently uses **two layers** of post-quantum security:

1. **Application Layer** (liboqs-python):
   - CRYSTALS-Kyber KEM for session key establishment
   - AES-256-GCM for message/document encryption
   - Implemented in `app/pq_transport.py`

2. **Transport Layer** (OQS-OpenSSL - when configured):
   - Post-quantum TLS/HTTPS with Kyber key exchange
   - Post-quantum certificate signatures (Dilithium, Falcon, etc.)
   - Implemented via oqs-provider

### Recommended Setup

For full OQS-OpenSSL integration, use a **reverse proxy** approach:

```
Client (Browser)
   │
   │ HTTPS (TLS 1.3) with OQS-OpenSSL
   │ Post-quantum cipher suites
   ▼
Nginx/Stunnel (compiled with OQS-OpenSSL)
   │
   │ HTTP (internal, localhost)
   ▼
FastAPI Backend (localhost:8000)
```

**Why?** Python's `ssl` module uses the system OpenSSL, which may not have oqs-provider loaded. A reverse proxy gives you full control over the TLS configuration.

## Building Components

### Prerequisites

1. **OpenSSL 3.x**
   - Download: https://slproweb.com/products/Win32OpenSSL.html
   - Install to: `C:\Program Files\OpenSSL-Win64`

2. **liboqs**
   - Clone: https://github.com/open-quantum-safe/liboqs
   - Build with CMake
   - Set `LIBOQS_DIR` environment variable

3. **CMake** - https://cmake.org/download/

4. **Visual Studio Build Tools** - For compiling C/C++

### Build Steps

#### Step 1: Build liboqs

```powershell
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release
```

Set environment variable:
```powershell
$env:LIBOQS_DIR = "C:\path\to\liboqs\build"
```

#### Step 2: Build oqs-provider

```powershell
cd backend
.\setup_oqs_openssl.ps1
```

Or manually:
```powershell
git clone https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider
cmake -S . -B _build -DCMAKE_BUILD_TYPE=Release -DLIBOQS_DIR=$env:LIBOQS_DIR
cmake --build _build --config Release
```

#### Step 3: Build Nginx with OQS-OpenSSL (Optional, for reverse proxy)

This is more complex and requires:
1. Building OQS-OpenSSL (fork of OpenSSL 3)
2. Building nginx against OQS-OpenSSL
3. Configuring nginx with post-quantum cipher suites

See: https://github.com/open-quantum-safe/oqs-openssl

## Testing

### Test Provider Loading

```powershell
$env:OPENSSL_MODULES = "C:\path\to\oqs-provider\_build\bin\Release"
openssl list -providers
openssl list -signature-algorithms | Select-String -Pattern "dilithium"
openssl list -kem-algorithms | Select-String -Pattern "kyber"
```

### Test TLS Connection

**Option 1: Using the test script (Recommended)**
```powershell
# Start server
.\start_server_https.ps1

# In another terminal, test connection with OQS provider
.\test_pq_tls.ps1
```

**Option 2: Manual testing with OQS provider loaded**
```powershell
# Set OQS provider path
$env:OPENSSL_MODULES = "C:\path\to\oqs-provider\_build\bin\Release"
$env:PATH = "$env:OPENSSL_MODULES;$env:PATH"

# List available groups
openssl s_client -help | Select-String -Pattern "groups"

# Test connection (try different group names)
openssl s_client -connect localhost:8443 -groups x25519_kyber512_draft00

# Or test with standard TLS (no specific group)
openssl s_client -connect localhost:8443
```

**Note:** The `-groups` option requires the OQS provider to be loaded. If you get "Call to SSL_CONF_cmd(-groups, kyber512) failed", it means:
1. The OQS provider is not loaded in your OpenSSL
2. The group name format might be different (try `x25519_kyber512_draft00` or `X25519Kyber512Draft00`)
3. Your OpenSSL version might not support the specific group name

Use the `test_pq_tls.ps1` script which automatically handles provider loading and tries multiple group formats.

### Verify Certificate

```powershell
openssl x509 -in certs\server.crt -text -noout
```

Look for:
- `Signature Algorithm: dilithium2` (or other PQ algorithm)
- Subject/Issuer information

## Configuration

### Environment Variables

Add to `backend/.env`:

```env
# HTTPS Configuration
USE_HTTPS=true
SSL_CERTFILE=certs/server.crt
SSL_KEYFILE=certs/server.key
OQS_PROVIDER_PATH=oqs-provider
```

### Python Configuration

The `app/oqs_ssl.py` module provides utilities for:
- Loading oqs-provider
- Creating SSL contexts
- Verifying OQS-OpenSSL availability

## Limitations

### Current Limitations

1. **Python's ssl Module**: Uses system OpenSSL, which may not have oqs-provider loaded
   - **Solution**: Use reverse proxy (nginx/stunnel) compiled with OQS-OpenSSL

2. **Browser Support**: Browsers don't natively support post-quantum TLS yet
   - **Solution**: Use a custom client or wait for browser support
   - **Workaround**: Application-layer PQ security (already implemented)

3. **Certificate Validation**: Self-signed certificates require browser exception
   - **Solution**: For production, use a CA-signed certificate (when PQ CAs exist)

### Workarounds

For demonstration purposes, the application uses:
- **Application-layer post-quantum security** (liboqs-python) - ✅ Working
- **TLS-level post-quantum security** (OQS-OpenSSL) - ⚠️ Requires reverse proxy for full support

## Documentation References

- **oqs-provider**: https://github.com/open-quantum-safe/oqs-provider
- **OQS-OpenSSL**: https://github.com/open-quantum-safe/oqs-openssl
- **liboqs**: https://github.com/open-quantum-safe/liboqs
- **Open Quantum Safe**: https://openquantumsafe.org/

## Troubleshooting

### "Provider not found"

- Check that `OPENSSL_MODULES` environment variable is set
- Verify provider DLL exists and is correct architecture (x64)
- Ensure OpenSSL 3.x is installed

### "Algorithm not found"

- Verify liboqs was built with the algorithm enabled
- Check OpenSSL version is 3.x (providers require OpenSSL 3+)

### Build errors

- Ensure all prerequisites are installed
- Check `LIBOQS_DIR` is set correctly
- Verify OpenSSL 3 is accessible

### Python ssl module doesn't use provider

- This is expected - Python uses its own OpenSSL
- Use reverse proxy for full OQS-OpenSSL support
- Application-layer PQ security still works

## Next Steps

1. ✅ Build oqs-provider (`setup_oqs_openssl.ps1`)
2. ✅ Generate certificates (`generate_pq_certificates.ps1`)
3. ⏳ Configure reverse proxy (nginx with OQS-OpenSSL) - Optional
4. ⏳ Test TLS handshake with post-quantum algorithms
5. ⏳ Document TLS handshake in project report

## Summary

This application implements post-quantum security at **two levels**:

1. **Application Layer**: ✅ Fully working with liboqs-python
   - CRYSTALS-Kyber KEM
   - AES-256-GCM encryption
   - Session key establishment

2. **Transport Layer**: ⚠️ Requires additional setup
   - OQS-OpenSSL provider for TLS
   - Post-quantum certificates
   - Reverse proxy recommended for full support

Both layers provide post-quantum security, ensuring the application is secure against quantum attacks.

