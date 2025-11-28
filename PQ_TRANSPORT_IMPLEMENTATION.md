# Post-Quantum Transport Security Implementation

## Summary

This implementation adds post-quantum "TLS-like" transport security to the messaging app. Messages are encrypted between the browser and server using CRYSTALS-Kyber KEM and AES-256-GCM.

## Architecture

### Flow

1. **Server Startup**: Server generates a Kyber KEM keypair
2. **Client Login**: After successful login, client performs PQ handshake:
   - Client fetches server's public key (`GET /pq/kem-public-key`)
   - Client performs Kyber KEM encapsulation → shared secret
   - Client sends ciphertext to server (`POST /pq/handshake`)
   - Both sides derive AES-256 session key using HKDF
3. **Message Sending**: 
   - Client encrypts message with AES-GCM using session key
   - Sends encrypted payload: `{ recipient_id, nonce, ciphertext }`
   - Server decrypts and stores plaintext in MongoDB
4. **Message Retrieval**: Server returns plaintext (already decrypted)

## Files Created/Modified

### Backend

**New Files:**
- `backend/app/pq_transport.py` - PQ KEM and AES-GCM utilities
- `backend/app/session_manager.py` - In-memory session key storage
- `backend/app/routers/pq.py` - PQ handshake endpoints

**Modified Files:**
- `backend/app/main.py` - Generate server keypair on startup, include PQ router
- `backend/app/models.py` - Updated `MessageCreate` to support encrypted payloads
- `backend/app/routers/messages.py` - Decrypt messages on receipt
- `backend/requirements.txt` - Added `liboqs-python`

### Frontend

**New Files:**
- `frontend/src/utils/crypto.ts` - Frontend crypto utilities (AES-GCM, HKDF, Kyber placeholder)
- `frontend/src/context/SessionKeyContext.tsx` - React context for session key
- `frontend/src/components/Login.tsx` - Updated to perform PQ handshake after login
- `frontend/src/components/Chat.tsx` - Updated to encrypt messages before sending
- `frontend/src/services/api.ts` - Added PQ API endpoints and encrypted message sending

**Modified Files:**
- `frontend/package.json` - Added `@noble/curves` (for future use)
- `frontend/src/main.tsx` - Added `SessionKeyProvider`

## Key Components

### Backend: PQ Transport Module (`pq_transport.py`)

- `generate_server_keypair()` - Generate Kyber keypair on startup
- `server_decapsulate()` - Server-side KEM decapsulation
- `derive_session_key()` - HKDF key derivation
- `encrypt_aes_gcm()` / `decrypt_aes_gcm()` - AES-256-GCM encryption/decryption

### Backend: Session Manager (`session_manager.py`)

- In-memory map: `user_id -> session_key`
- `store_session_key()` - Store key after handshake
- `get_session_key()` - Retrieve key for decryption

### Backend: PQ Router (`routers/pq.py`)

- `GET /pq/kem-public-key` - Returns server's public key
- `POST /pq/handshake` - Accepts client ciphertext, establishes session key

### Frontend: Crypto Utilities (`utils/crypto.ts`)

- `performKyberEncapsulation()` - Client-side KEM encapsulation (simplified for demo)
- `deriveSessionKey()` - HKDF key derivation using Web Crypto API
- `encryptMessage()` / `decryptMessage()` - AES-256-GCM using Web Crypto API

### Frontend: Session Key Context (`context/SessionKeyContext.tsx`)

- React context to store session key in memory
- Accessed via `useSessionKey()` hook

## Installation

### Backend

```bash
cd PostQuantumMessagingApp/backend
pip install -r requirements.txt
```

**Important**: Make sure `liboqs-python` is installed. If not, the code will use a fallback (NOT secure).

### Frontend

```bash
cd PostQuantumMessagingApp/frontend
npm install
```

## Usage

1. Start backend: `uvicorn app.main:app --reload`
2. Start frontend: `npm run dev`
3. Login - PQ handshake happens automatically
4. Send messages - they are encrypted with AES-GCM

## Security Notes

### What This Provides

- **Transport Security**: Messages encrypted between browser and server
- **Post-Quantum Safe**: Uses CRYSTALS-Kyber (quantum-resistant)
- **Authenticated Encryption**: AES-GCM provides encryption + authentication

### What This Does NOT Provide

- **End-to-End Encryption**: Server can decrypt and read all messages
- **Message Encryption at Rest**: Messages stored as plaintext in MongoDB
- **Forward Secrecy**: Session keys persist until logout/server restart

### Important Limitations

1. **Frontend Kyber Implementation**: Currently uses a simplified placeholder. For production, replace with a proper Kyber library (WebAssembly-based or similar).

2. **Session Key Storage**: Keys stored in-memory only. Lost on server restart. For multi-instance deployments, use Redis or similar.

3. **No Key Rotation**: Session keys don't expire or rotate automatically.

## Testing

1. **Test Handshake**:
   - Login and check browser console for `[PQ]` logs
   - Verify session key is stored in context

2. **Test Encryption**:
   - Send a message
   - Check browser console for `[PQ] Encrypting message...`
   - Check backend logs for `[PQ] Decrypted message...`

3. **Test Backward Compatibility**:
   - Messages can still be sent as plaintext if no session key exists
   - Server accepts both formats

## Next Steps for Production

1. Replace frontend Kyber implementation with a proper library
2. Add session key persistence (Redis) for multi-instance
3. Implement key rotation/refresh
4. Add proper error handling for encryption failures
5. Consider adding message authentication at application layer
6. Add logging/auditing for security events

## Code Comments

All code includes beginner-friendly comments explaining:
- What each function does
- Why certain cryptographic operations are performed
- How the PQ handshake works
- How AES-GCM encryption/decryption works

This makes it easy to understand the implementation for learning purposes.

