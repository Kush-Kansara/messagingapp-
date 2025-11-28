# Post-Quantum Transport Security Implementation Notes

## Overview

This implementation adds post-quantum "TLS-like" transport security between the React frontend and FastAPI backend using CRYSTALS-Kyber KEM and AES-256-GCM.

## Important Notes

### Backend

1. **liboqs-python Installation**: The backend requires `liboqs-python` for Kyber KEM operations.
   ```bash
   pip install liboqs-python
   ```
   
   If `liboqs-python` is not installed, the code will use a fallback implementation (NOT secure - for demo only).

2. **Server Keypair**: The server generates a Kyber keypair on startup. The public key is exposed via `/pq/kem-public-key`.

3. **Session Keys**: After handshake, each user gets a session key stored in memory (user_id -> session_key map).

### Frontend

1. **Kyber Library**: The frontend currently uses a simplified Kyber implementation for demonstration.
   
   **For production, you MUST replace this with a proper Kyber library:**
   - Use a WebAssembly-based Kyber implementation
   - Or use a JavaScript Kyber library that works in browsers
   - Or use `pqc-kyber` or similar if available
   
   The current implementation in `src/utils/crypto.ts` is a placeholder that demonstrates the concept but is NOT cryptographically secure.

2. **Session Key Storage**: Session keys are stored in React context (in-memory only, NOT in localStorage).

3. **Handshake Flow**: After login, the client:
   - Fetches server's public key
   - Performs Kyber encapsulation
   - Sends ciphertext to server
   - Derives session key locally

## Installation

### Backend

```bash
cd PostQuantumMessagingApp/backend
pip install -r requirements.txt
```

### Frontend

```bash
cd PostQuantumMessagingApp/frontend
npm install
```

## Usage

1. Start the backend server
2. Start the frontend dev server
3. Login - the PQ handshake happens automatically
4. Send messages - they are encrypted with AES-GCM using the session key

## Security Considerations

1. **This is NOT end-to-end encryption** - the server can decrypt and read all messages
2. **This is transport security** - messages are encrypted between browser and server
3. **Session keys are in-memory only** - they are lost on server restart
4. **For production**, replace the simplified frontend Kyber implementation with a proper library

## Next Steps for Production

1. Replace frontend Kyber implementation with a proper library
2. Add session key persistence (Redis) for multi-instance deployments
3. Add key rotation/refresh mechanism
4. Add proper error handling for encryption failures
5. Consider adding message authentication (already included in AES-GCM)

