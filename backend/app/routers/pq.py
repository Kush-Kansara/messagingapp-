"""
Post-Quantum Transport Security Router
======================================

This router handles the PQ handshake between client and server:
1. GET /pq/kem-public-key - Returns server's Kyber public key
2. POST /pq/handshake - Client sends KEM ciphertext, server derives session key

After handshake, all message traffic is encrypted with AES-GCM using the session key.
"""

from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel
from app.auth import get_current_user
from app.pq_transport import (
    get_server_public_key,
    server_decapsulate,
    derive_session_key
)
from app.session_manager import store_session_key
import base64

router = APIRouter(prefix="/pq", tags=["post-quantum"])


class HandshakeRequest(BaseModel):
    """Request model for PQ handshake"""
    ciphertext: str  # Base64-encoded KEM ciphertext from client


class HandshakeResponse(BaseModel):
    """Response model for PQ handshake"""
    status: str
    message: str


@router.get("/kem-public-key")
async def get_kem_public_key():
    """
    Get the server's Kyber public key.
    
    This endpoint is called by the client to get the server's public key
    so they can perform KEM encapsulation and establish a shared secret.
    
    No authentication required - the public key is safe to share.
    
    Returns:
        JSON with base64-encoded public key
    """
    try:
        public_key = get_server_public_key()
        public_key_b64 = base64.b64encode(public_key).decode('utf-8')
        return {"public_key": public_key_b64}
    except RuntimeError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Server keypair not initialized: {str(e)}"
        )


@router.post("/handshake", response_model=HandshakeResponse)
async def handshake(
    handshake_data: HandshakeRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Perform post-quantum handshake to establish a session key.
    
    Flow:
    1. Client sends KEM ciphertext (from encapsulation with server's public key)
    2. Server decapsulates to get shared secret
    3. Server derives AES-256 session key using HKDF
    4. Server stores session key associated with user_id
    5. Client also derives the same session key on their side
    
    After this, all messages are encrypted with AES-GCM using this session key.
    
    Args:
        handshake_data: Contains base64-encoded KEM ciphertext
        current_user: Authenticated user (from JWT cookie)
    
    Returns:
        Success response
    """
    user_id = str(current_user["_id"])
    
    try:
        # Decode the KEM ciphertext from base64
        ciphertext = base64.b64decode(handshake_data.ciphertext)
        
        # Server performs KEM decapsulation to get the shared secret
        # This is the "server side" of the key exchange
        shared_secret = server_decapsulate(ciphertext)
        
        # Derive a symmetric AES-256 key from the shared secret using HKDF
        # HKDF ensures we get a proper 256-bit key for AES-256
        session_key = derive_session_key(shared_secret, info=b"pq_transport_session")
        
        # Store the session key for this user
        # This key will be used to decrypt all messages from this user
        store_session_key(user_id, session_key)
        
        print(f"[PQ_HANDSHAKE] Successfully established session key for user {current_user['username']} (ID: {user_id})")
        
        return HandshakeResponse(
            status="ok",
            message="Handshake successful. Session key established."
        )
    
    except Exception as e:
        print(f"[PQ_HANDSHAKE] Error for user {user_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Handshake failed: {str(e)}"
        )

