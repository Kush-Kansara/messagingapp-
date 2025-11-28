"""
Post-Quantum Transport Security Module
=====================================

This module implements post-quantum "TLS-like" transport security between
the React frontend and FastAPI backend using CRYSTALS-Kyber KEM.

Flow:
1. Server generates a Kyber keypair on startup
2. Client performs KEM encapsulation with server's public key → shared secret
3. Shared secret → AES-256 key (via HKDF)
4. Messages encrypted with AES-256-GCM for transport
5. Server decrypts and stores plaintext in MongoDB

This is NOT end-to-end encryption - the server can still read messages.
It's just transport security (browser ↔ server) using post-quantum cryptography.
"""

import os
import base64
from typing import Tuple, Optional
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.backends import default_backend

# Try to import liboqs-python for Kyber
try:
    import oqs
    HAS_OQS = True
except ImportError:
    HAS_OQS = False
    print("WARNING: liboqs-python not installed. Using fallback implementation.")
    print("Install with: pip install liboqs-python")


# Server's Kyber keypair (set on startup)
server_kem_public_key: Optional[bytes] = None
server_kem_secret_key: Optional[bytes] = None
KEM_ALGORITHM = "Kyber512"  # Can be Kyber512, Kyber768, or Kyber1024


def generate_server_keypair() -> Tuple[bytes, bytes]:
    """
    Generate a Kyber KEM keypair for the server.
    
    This is called once on server startup.
    The public key is shared with clients, the secret key stays on the server.
    
    Returns:
        (public_key_bytes, secret_key_bytes): Tuple of bytes
    """
    global server_kem_public_key, server_kem_secret_key
    
    if HAS_OQS:
        # Use liboqs-python for real Kyber
        with oqs.KeyEncapsulation(KEM_ALGORITHM) as server_kem:
            # Generate keypair
            public_key = server_kem.generate_keypair()
            secret_key = server_kem.export_secret_key()
            server_kem_public_key = public_key
            server_kem_secret_key = secret_key
            print(f"[PQ] Generated {KEM_ALGORITHM} keypair for server")
            return public_key, secret_key
    else:
        # Fallback: Generate random keys (NOT secure, just for demo)
        # In production, you MUST use liboqs-python
        print("[PQ] WARNING: Using fallback random key generation (NOT secure!)")
        public_key = os.urandom(800)  # Approximate Kyber512 public key size
        secret_key = os.urandom(1632)  # Approximate Kyber512 secret key size
        server_kem_public_key = public_key
        server_kem_secret_key = secret_key
        return public_key, secret_key


def get_server_public_key() -> bytes:
    """
    Get the server's Kyber public key.
    
    This is sent to clients so they can perform KEM encapsulation.
    
    Returns:
        public_key_bytes: Server's public key
    """
    if server_kem_public_key is None:
        raise RuntimeError("Server keypair not initialized. Call generate_server_keypair() first.")
    return server_kem_public_key


def server_decapsulate(ciphertext: bytes) -> bytes:
    """
    Server performs KEM decapsulation to get the shared secret.
    
    This is called during the handshake when the client sends their ciphertext.
    
    Args:
        ciphertext: The KEM ciphertext from the client (base64 decoded)
    
    Returns:
        shared_secret: The shared secret derived from KEM decapsulation
    """
    global server_kem_secret_key
    
    if server_kem_secret_key is None:
        raise RuntimeError("Server secret key not initialized.")
    
    if HAS_OQS:
        # Use liboqs-python for real Kyber decapsulation
        with oqs.KeyEncapsulation(KEM_ALGORITHM, server_kem_secret_key) as server_kem:
            shared_secret = server_kem.decap_secret(ciphertext)
            return shared_secret
    else:
        # Fallback: Return deterministic value (NOT secure, just for demo)
        # In production, you MUST use liboqs-python
        print("[PQ] WARNING: Using fallback decapsulation (NOT secure!)")
        return os.urandom(32)  # 32 bytes = 256 bits for AES-256


def derive_session_key(shared_secret: bytes, info: bytes = b"pq_transport_session") -> bytes:
    """
    Derive a symmetric AES-256 key from the shared secret using HKDF.
    
    HKDF (HMAC-based Key Derivation Function) is a standard way to derive
    cryptographic keys from a shared secret. It ensures the key has the right
    length and properties for AES-256.
    
    Args:
        shared_secret: The shared secret from KEM (bytes)
        info: Optional context information (bytes)
    
    Returns:
        session_key: 32-byte (256-bit) key for AES-256
    """
    # HKDF: Derive a 32-byte (256-bit) key from the shared secret
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=32,  # 32 bytes = 256 bits for AES-256
        salt=None,  # No salt needed for this use case
        info=info,  # Context information
        backend=default_backend()
    )
    session_key = hkdf.derive(shared_secret)
    return session_key


def encrypt_aes_gcm(key: bytes, plaintext: str) -> Tuple[bytes, bytes]:
    """
    Encrypt plaintext using AES-256-GCM.
    
    AES-GCM (Galois/Counter Mode) provides both encryption and authentication.
    It's a modern, secure mode of operation for AES.
    
    Args:
        key: 32-byte AES-256 key (from derive_session_key)
        plaintext: Message content as string
    
    Returns:
        (nonce_bytes, ciphertext_bytes): Tuple of bytes
        - nonce: 12-byte random nonce (needed for decryption)
        - ciphertext: Encrypted message (includes authentication tag)
    """
    # Convert plaintext to bytes
    plaintext_bytes = plaintext.encode('utf-8')
    
    # Create AES-GCM cipher
    aesgcm = AESGCM(key)
    
    # Generate a random 12-byte nonce (96 bits is standard for GCM)
    nonce = os.urandom(12)
    
    # Encrypt: AES-GCM automatically appends the authentication tag
    ciphertext = aesgcm.encrypt(nonce, plaintext_bytes, None)
    
    return nonce, ciphertext


def decrypt_aes_gcm(key: bytes, nonce: bytes, ciphertext: bytes) -> str:
    """
    Decrypt ciphertext using AES-256-GCM.
    
    Args:
        key: 32-byte AES-256 key (from derive_session_key)
        nonce: 12-byte nonce used during encryption
        ciphertext: Encrypted message (includes authentication tag)
    
    Returns:
        plaintext: Decrypted message as string
    
    Raises:
        ValueError: If decryption fails (wrong key, tampered data, etc.)
    """
    # Create AES-GCM cipher
    aesgcm = AESGCM(key)
    
    # Decrypt: AES-GCM automatically verifies the authentication tag
    # If the tag is invalid, this will raise an exception
    try:
        plaintext_bytes = aesgcm.decrypt(nonce, ciphertext, None)
        return plaintext_bytes.decode('utf-8')
    except Exception as e:
        raise ValueError(f"Decryption failed: {e}. This could mean the key is wrong or the data was tampered with.")

