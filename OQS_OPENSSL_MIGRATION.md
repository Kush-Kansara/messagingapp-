# Migrating to OQS-OpenSSL 3

Your current implementation already uses liboqs-python and CRYSTALS-Kyber for post-quantum transport security. To satisfy the exact project requirement of “using OQS-OpenSSL 3”, we can integrate the official **oqs-openssl** fork to terminate TLS connections with post-quantum cipher suites.

This document outlines the migration plan.

---

## 1. Target Architecture

```
Client (browser or custom client)
   │
   │  HTTPS (TLS 1.3) with OQS-OpenSSL 3
   ▼
OQS-enabled TLS proxy (nginx/apache/stunnel built with oqs-openssl)
   │
   │  Plain HTTP (internal)
   ▼
FastAPI backend (existing application)
```

### Rationale
- We keep FastAPI/React logic intact.
- A reverse proxy compiled with oqs-openssl handles TLS termination using post-quantum algorithms.
- Clients connect via HTTPS and therefore “use OQS-OpenSSL 3” for the protected channel.

---

## 2. Required Components

1. **oqs-openssl 3** (OpenSSL fork with PQC support)
2. **oqs-provider** or preconfigured cipher suites (e.g., `pqc_kyber512` + classical hybrid)
3. **nginx** or **stunnel** compiled against oqs-openssl
4. **Client** using oqs-openssl (CLI or custom executable) to demonstrate PQ TLS handshake

---

## 3. Migration Steps

### Step 1: Build oqs-openssl
1. Clone https://github.com/open-quantum-safe/oqs-openssl/tree/OQS-OpenSSL_3_0-stable  
2. Follow the build instructions (requires CMake, Perl, etc.)
3. Install to a known prefix, e.g., `C:\oqs-openssl` or `/usr/local/oqs-openssl`

### Step 2: Build nginx/stunnel with oqs-openssl
Option A: **nginx** (recommended)
- Download nginx source
- Configure with `--with-openssl=/path/to/oqs-openssl` and PQ options
- Compile and install

Option B: **stunnel**
- Build stunnel and link it against oqs-openssl
- Configure stunnel to forward TLS traffic to FastAPI (`localhost:8000`)

### Step 3: Configure TLS Certificates
- Use oqs-openssl to generate certificates with PQC cipher suites (e.g., `oqs_sig_default`)
- Configure nginx/stunnel to listen on `443` and forward to `localhost:8000`
- Enable PQC ciphers: e.g., `TLS_AES_256_GCM_SHA384:OQS-KYBER_LEVEL1` hybrids

### Step 4: Client Setup
- Build the oqs-openssl `s_client` for testing:
  ```
  oqs_openssl s_client -connect localhost:443 -groups kyber512
  ```
- Optionally, create a small CLI client (Python `requests` won’t pick up oqs-openssl automatically, so use the oqs-openssl binary or a custom C client).

### Step 5: Documentation & Demo
- Update README with instructions for running the TLS proxy.
- Document how to test the PQ TLS handshake (screenshots/logs from `s_client`).
- Note that the backend still uses liboqs-python for application-layer PQ transport (optional but nice).

---

## 4. Additional Enhancements

1. **Serve Static Documents**  
   - Add a directory of HTML/PDF documents served under `/docs` via FastAPI or nginx.
   - Demonstrates “server maintains a database of web pages/documents.”

2. **Client Authentication**  
   - Use PQ signature suites (e.g., Dilithium) for mutual TLS or signed tokens.

3. **Testing Script**  
   - Provide a script that runs `oqs_openssl s_client` and hits your endpoints.

---

## 5. Next Actions Checklist

1. [ ] Build oqs-openssl 3.0 fork  
2. [ ] Build nginx (or stunnel) against oqs-openssl  
3. [ ] Configure TLS proxy with PQ cipher suites  
4. [ ] Update FastAPI to trust proxy headers (if needed)  
5. [ ] Add documentation & screenshots/logs  
6. [ ] Optional: serve sample HTML documents to match assignment

Once these steps are complete, your project will explicitly use OQS-OpenSSL 3 for the protected channel, satisfying the assignment requirement while keeping your existing application logic.

