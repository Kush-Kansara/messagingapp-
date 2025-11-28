"""
Session Key Manager
===================

Simple in-memory storage for user session keys.

After a successful PQ handshake, each user gets a session_key derived from
the post-quantum KEM shared secret. This key is used to encrypt/decrypt
messages during transport.

For a single-process setup (dev/demo), this is sufficient.
For production with multiple server instances, you'd need Redis or similar.
"""

from typing import Dict, Optional

# In-memory map: user_id (string) -> session_key (bytes)
# This stores the AES-256 session key for each authenticated user
session_keys: Dict[str, bytes] = {}


def store_session_key(user_id: str, session_key: bytes) -> None:
    """
    Store a session key for a user.
    
    Called after successful PQ handshake.
    
    Args:
        user_id: User's ID as string
        session_key: 32-byte AES-256 key
    """
    session_keys[user_id] = session_key
    print(f"[SESSION] Stored session key for user {user_id}")


def get_session_key(user_id: str) -> Optional[bytes]:
    """
    Retrieve a user's session key.
    
    Args:
        user_id: User's ID as string
    
    Returns:
        session_key: 32-byte AES-256 key, or None if not found
    """
    return session_keys.get(user_id)


def clear_session_key(user_id: str) -> None:
    """
    Remove a user's session key (e.g., on logout).
    
    Args:
        user_id: User's ID as string
    """
    if user_id in session_keys:
        del session_keys[user_id]
        print(f"[SESSION] Cleared session key for user {user_id}")


def has_session_key(user_id: str) -> bool:
    """
    Check if a user has an active session key.
    
    Args:
        user_id: User's ID as string
    
    Returns:
        True if session key exists, False otherwise
    """
    return user_id in session_keys

