# OQS-OpenSSL Setup Checklist

Follow these steps in order to set up OQS-OpenSSL 3 provider for your post-quantum secure document server.

## Prerequisites Check

Before starting, ensure you have:

- [ ] **OpenSSL 3.x** installed
  - Download: https://slproweb.com/products/Win32OpenSSL.html
  - Install to: `C:\Program Files\OpenSSL-Win64`
  - Verify: `openssl version` should show "OpenSSL 3.x"

- [ ] **liboqs** built and `LIBOQS_DIR` environment variable set
  - Clone: https://github.com/open-quantum-safe/liboqs
  - Build with CMake
  - Set `LIBOQS_DIR` to build directory
  - Verify: `echo $env:LIBOQS_DIR` shows the path

- [ ] **CMake** installed
  - Download: https://cmake.org/download/
  - Verify: `cmake --version`

- [ ] **Visual Studio Build Tools** or **Visual Studio** with C++ support
  - Required for compiling C/C++ code
  - Verify: `cl` command works (or use Developer Command Prompt)

- [ ] **Git** installed
  - Verify: `git --version`

## Step-by-Step Setup

### Step 1: Build OQS-Provider

```powershell
cd backend
.\setup_oqs_openssl.ps1
```

**What this does:**
- Clones oqs-provider repository (if not present)
- Checks for prerequisites
- Builds oqs-provider with CMake
- Copies provider library to `backend/oqs-provider/`

**Expected output:**
- `[OK]` messages for each check
- Build completes without errors
- Provider DLL found at `backend/oqs-provider/oqsprov.dll`

**If errors occur:**
- Check that all prerequisites are installed
- Verify `LIBOQS_DIR` is set correctly
- Ensure OpenSSL 3.x is installed
- Try running from "Developer Command Prompt for VS"

### Step 2: Generate Post-Quantum Certificates

```powershell
cd backend
.\generate_pq_certificates.ps1 -ProviderPath "oqs-provider" -SignatureAlg "dilithium2"
```

**What this does:**
- Generates private key with post-quantum signature algorithm (Dilithium2)
- Creates self-signed certificate
- Saves to `backend/certs/server.key` and `backend/certs/server.crt`

**Expected output:**
- `[OK] Private key generated`
- `[OK] Certificate generated`
- Certificate details displayed

**If Dilithium2 not available:**
- Script will fall back to RSA
- This is OK for testing, but won't be post-quantum
- Check that oqs-provider was built correctly

**Alternative algorithms:**
```powershell
# Try different algorithms
.\generate_pq_certificates.ps1 -SignatureAlg "falcon512"
.\generate_pq_certificates.ps1 -SignatureAlg "sphincssha256128frobust"
```

### Step 3: Verify Setup

```powershell
# Check provider is available
$env:OPENSSL_MODULES = "backend\oqs-provider"
openssl list -providers

# Check for post-quantum algorithms
openssl list -signature-algorithms | Select-String -Pattern "dilithium|falcon"
openssl list -kem-algorithms | Select-String -Pattern "kyber"
```

**Expected output:**
- Provider list shows "oqsprovider" or similar
- Post-quantum algorithms listed

**If not working:**
- Verify provider DLL exists
- Check OpenSSL version is 3.x
- Ensure `OPENSSL_MODULES` points to correct directory

### Step 4: Start Server with HTTPS

```powershell
cd backend
.\start_server_https.ps1
```

**What this does:**
- Activates virtual environment
- Sets up OQS provider environment
- Starts uvicorn with HTTPS on port 8443
- Uses post-quantum certificates

**Expected output:**
- `[OK] Certificate: certs\server.crt`
- `[OK] Private key: certs\server.key`
- Server starts on `https://localhost:8443`
- Uvicorn logs show server running

**Access the server:**
- Browser: `https://localhost:8443` (accept security warning for self-signed cert)
- API docs: `https://localhost:8443/docs`

### Step 5: Test TLS Connection

Open a **new terminal** and test the connection:

```powershell
# Test with OpenSSL client
openssl s_client -connect localhost:8443 -groups kyber512
```

**Expected output:**
- Connection established
- Certificate information displayed
- Shows "New, TLSv1.3" (or similar)
- May show post-quantum cipher suite if supported

**If connection fails:**
- Check server is running
- Verify port 8443 is not blocked
- Check firewall settings

## Verification Checklist

After setup, verify everything works:

- [ ] OQS-provider built successfully
- [ ] Certificates generated with post-quantum algorithm
- [ ] Server starts with HTTPS
- [ ] Can access `https://localhost:8443` in browser
- [ ] API endpoints work (test `/documents` endpoint)
- [ ] TLS connection test succeeds

## Using the Application

### Upload a Document

```powershell
# Example: Upload HTML document
curl -X POST "https://localhost:8443/documents" `
  -H "Content-Type: application/json" `
  -H "Cookie: access_token=YOUR_JWT_TOKEN" `
  -d '{"title": "My Page", "content": "<html><body><h1>Hello World</h1></body></html>"}'
```

### List Documents

```powershell
curl "https://localhost:8443/documents"
```

### Get Document

```powershell
curl "https://localhost:8443/documents/{document_id}"
```

## Troubleshooting

### Issue: "Provider not found"

**Solution:**
- Verify `OPENSSL_MODULES` environment variable is set
- Check provider DLL exists at `backend/oqs-provider/oqsprov.dll`
- Ensure OpenSSL 3.x is installed

### Issue: "Algorithm not found"

**Solution:**
- Verify liboqs was built with the algorithm enabled
- Check OpenSSL version is 3.x
- Try a different algorithm (e.g., `falcon512` instead of `dilithium2`)

### Issue: "Build failed"

**Solution:**
- Ensure all prerequisites are installed
- Check `LIBOQS_DIR` is set correctly
- Try building from "Developer Command Prompt for VS"
- Check CMake output for specific errors

### Issue: "Certificate generation failed"

**Solution:**
- Verify OpenSSL 3.x is installed
- Check provider path is correct
- Try with RSA fallback first: `.\generate_pq_certificates.ps1` (without -SignatureAlg)

### Issue: "Server won't start with HTTPS"

**Solution:**
- Verify certificates exist: `Test-Path certs\server.crt`
- Check certificate and key paths in `.env` file
- Try starting without HTTPS first: `.\start_server.ps1`

## Next Steps After Setup

1. **Test document upload** via API
2. **Test document retrieval** via API
3. **Verify post-quantum handshake** (check server logs)
4. **Update frontend** to use HTTPS endpoint
5. **Document your setup** for project report

## For Project Documentation

When documenting your project:

1. **Screenshot** the setup process
2. **Show** certificate details (post-quantum algorithm)
3. **Demonstrate** TLS connection with `openssl s_client`
4. **Explain** both layers of post-quantum security:
   - Application layer (liboqs-python)
   - Transport layer (OQS-OpenSSL)
5. **Show** that documents are stored securely

## Quick Reference

```powershell
# Build provider
.\setup_oqs_openssl.ps1

# Generate certificates
.\generate_pq_certificates.ps1 -ProviderPath "oqs-provider" -SignatureAlg "dilithium2"

# Start HTTPS server
.\start_server_https.ps1

# Test connection
openssl s_client -connect localhost:8443 -groups kyber512

# Regular HTTP server (for development)
.\start_server.ps1
```

## Support

If you encounter issues:

1. Check the error messages carefully
2. Verify all prerequisites are installed
3. Review `OQS_OPENSSL_SETUP.md` for detailed information
4. Check `backend/README_OQS_OPENSSL.md` for troubleshooting

Good luck! 🚀

