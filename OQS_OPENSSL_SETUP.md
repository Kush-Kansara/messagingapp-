# OQS-OpenSSL Provider Setup Guide

This guide explains how to set up and use the OQS-OpenSSL provider for post-quantum TLS/HTTPS in this application.

## Overview

The **oqs-provider** is an OpenSSL 3 provider that adds post-quantum cryptographic algorithms to OpenSSL. This allows you to use post-quantum algorithms (like CRYSTALS-Kyber) in TLS/HTTPS connections.

**Repository**: https://github.com/open-quantum-safe/oqs-provider

## Prerequisites

1. **OpenSSL 3.x** - Required for provider support
   - Download from: https://slproweb.com/products/Win32OpenSSL.html
   - Install to default location: `C:\Program Files\OpenSSL-Win64`

2. **liboqs** - The underlying post-quantum cryptography library
   - Clone: https://github.com/open-quantum-safe/liboqs
   - Build using CMake (see liboqs documentation)
   - Set `LIBOQS_DIR` environment variable to build directory

3. **CMake** - For building oqs-provider
   - Download from: https://cmake.org/download/

4. **Visual Studio Build Tools** or **Visual Studio** with C++ support
   - Required for compiling C/C++ code

5. **Git** - For cloning repositories

## Quick Setup (Windows)

### Step 1: Run Setup Script

```powershell
cd backend
.\setup_oqs_openssl.ps1
```

This script will:
- Clone oqs-provider repository (if not already present)
- Check for OpenSSL 3 and liboqs
- Build oqs-provider
- Copy provider library to `backend/oqs-provider/`

### Step 2: Configure OpenSSL

Create an OpenSSL configuration file that loads oqs-provider.

**Location**: `backend/openssl.cnf`

```ini
openssl_conf = openssl_init

[openssl_init]
providers = provider_sect

[provider_sect]
default = default_sect
oqsprovider = oqsprovider_sect

[default_sect]
activate = 1

[oqsprovider_sect]
activate = 1
```

**Note**: The actual provider loading is done programmatically in Python, not via config file.

### Step 3: Generate Post-Quantum Certificates

Use OpenSSL with oqs-provider to generate certificates with post-quantum algorithms.

**Generate private key with post-quantum signature algorithm (e.g., Dilithium2):**

```powershell
# Set environment variable to point to provider
$env:OPENSSL_MODULES = "C:\path\to\oqs-provider\_build\bin\Release"

# Generate private key
openssl genpkey -algorithm dilithium2 -out server.key

# Generate certificate signing request
openssl req -new -key server.key -out server.csr -subj "/CN=localhost"

# Generate self-signed certificate (valid for 365 days)
openssl x509 -req -in server.csr -signkey server.key -out server.crt -days 365
```

**Or use Kyber for key exchange (in TLS handshake):**

The key exchange algorithm is negotiated during TLS handshake, not in the certificate. The certificate uses signature algorithms (like Dilithium), while key exchange uses KEM algorithms (like Kyber).

### Step 4: Configure Python to Use OQS-OpenSSL

Python's `ssl` module uses the system OpenSSL. To use OQS-OpenSSL:

1. **Option A: Replace system OpenSSL** (not recommended - affects entire system)

2. **Option B: Use OQS-OpenSSL via subprocess** (recommended for testing)

3. **Option C: Use a reverse proxy** (recommended for production)
   - Build nginx with OQS-OpenSSL
   - Configure nginx to terminate TLS with post-quantum algorithms
   - Forward to FastAPI backend over HTTP

## Integration with FastAPI/Uvicorn

### Option 1: Direct HTTPS with OQS-OpenSSL (Advanced)

This requires building Python with OQS-OpenSSL, which is complex. Not recommended.

### Option 2: Reverse Proxy (Recommended)

Use nginx or stunnel compiled with OQS-OpenSSL:

1. **Build nginx with OQS-OpenSSL**:
   ```powershell
   # Clone nginx
   git clone http://hg.nginx.org/nginx
   
   # Build with OQS-OpenSSL (requires custom build)
   # See: https://github.com/open-quantum-safe/oqs-openssl
   ```

2. **Configure nginx** to use post-quantum cipher suites:
   ```nginx
   server {
       listen 443 ssl;
       server_name localhost;
       
       ssl_certificate server.crt;
       ssl_certificate_key server.key;
       
       # Enable post-quantum cipher suites
       ssl_ciphers 'TLS_AES_256_GCM_SHA384:ECDHE-KYBER512-RSA-AES256-GCM-SHA384';
       ssl_protocols TLSv1.3;
       
       location / {
           proxy_pass http://localhost:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

### Option 3: Use Python's ssl Module with OQS-OpenSSL (Testing)

For testing purposes, you can use Python's `ssl` module if Python was built against OQS-OpenSSL:

```python
import ssl
import uvicorn

# Create SSL context with post-quantum algorithms
ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ssl_context.load_cert_chain("server.crt", "server.key")

# Start server with HTTPS
uvicorn.run(
    "app.main:app",
    host="0.0.0.0",
    port=8443,
    ssl_keyfile="server.key",
    ssl_certfile="server.crt"
)
```

## Testing OQS-OpenSSL

### Test Provider Loading

```powershell
# Set provider path
$env:OPENSSL_MODULES = "C:\path\to\oqs-provider\_build\bin\Release"

# List available algorithms
openssl list -providers
openssl list -signature-algorithms | Select-String -Pattern "dilithium"
openssl list -kem-algorithms | Select-String -Pattern "kyber"
```

### Test TLS Connection

```powershell
# Start server with HTTPS
# Then test with:
openssl s_client -connect localhost:8443 -groups kyber512
```

## Current Implementation Status

The current application uses **liboqs-python** for application-layer post-quantum cryptography (KEM key exchange for session keys). This is different from TLS-level post-quantum security.

To fully satisfy the requirement of "using OQS-OpenSSL 3", you need to:

1. ✅ Build oqs-provider (use `setup_oqs_openssl.ps1`)
2. ⏳ Configure TLS/HTTPS with post-quantum cipher suites
3. ⏳ Set up reverse proxy or configure uvicorn for HTTPS
4. ⏳ Test TLS handshake with post-quantum algorithms

## Documentation References

- **oqs-provider**: https://github.com/open-quantum-safe/oqs-provider
- **OQS-OpenSSL**: https://github.com/open-quantum-safe/oqs-openssl
- **liboqs**: https://github.com/open-quantum-safe/liboqs
- **Open Quantum Safe Project**: https://openquantumsafe.org/

## Troubleshooting

### "Provider not found" error

- Make sure `OPENSSL_MODULES` environment variable points to the provider DLL location
- Verify the provider DLL exists and is the correct architecture (x64)

### "Algorithm not found" error

- Check that liboqs was built with the algorithm enabled
- Verify OpenSSL version is 3.x (providers require OpenSSL 3+)

### Build errors

- Ensure all prerequisites are installed (CMake, Visual Studio Build Tools)
- Check that `LIBOQS_DIR` is set correctly
- Verify OpenSSL 3 is installed and accessible

## Next Steps

1. Complete the setup using `setup_oqs_openssl.ps1`
2. Generate post-quantum certificates
3. Configure server for HTTPS with post-quantum algorithms
4. Test TLS connection with `openssl s_client`
5. Document the TLS handshake in project report

