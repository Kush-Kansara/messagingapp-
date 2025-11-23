from fastapi import APIRouter, HTTPException, status, Depends, Query
from datetime import datetime
from typing import List
from app.models import MessageCreate, MessageResponse
from app.auth import get_current_user
from app.encryption import encrypt_message, decrypt_message
from app import database as db_module
from bson import ObjectId, Binary

router = APIRouter(prefix="/messages", tags=["messages"])


@router.post("", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    message_data: MessageCreate,
    current_user: dict = Depends(get_current_user)
):
    """Send a message to a specific user"""
    if not message_data.content or not message_data.content.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message content cannot be empty"
        )
    
    # Validate recipient_id
    if not ObjectId.is_valid(message_data.recipient_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid recipient ID"
        )
    
    recipient_id = ObjectId(message_data.recipient_id)
    
    # Check if recipient exists
    recipient = await db_module.database.users.find_one({"_id": recipient_id})
    if not recipient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recipient user not found"
        )
    
    # Don't allow sending to yourself
    if recipient_id == ObjectId(current_user["_id"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot send message to yourself"
        )
    
    # Encrypt the message content
    ciphertext, nonce, auth_tag = encrypt_message(message_data.content)
    
    # Create message document
    # Store binary data as Binary for proper MongoDB handling
    message_doc = {
        "sender_id": ObjectId(current_user["_id"]),
        "sender_username": current_user["username"],
        "recipient_id": recipient_id,
        "recipient_username": recipient["username"],
        "content_encrypted": Binary(ciphertext),
        "nonce": Binary(nonce),
        "auth_tag": Binary(auth_tag),
        "timestamp": datetime.utcnow()
    }
    
    # Insert message
    result = await db_module.database.messages.insert_one(message_doc)
    message_doc["_id"] = result.inserted_id
    
    # Return decrypted message for response
    return MessageResponse(
        id=str(message_doc["_id"]),
        username=message_doc["sender_username"],
        content=message_data.content,  # Return original plaintext
        timestamp=message_doc["timestamp"],
        sender_id=str(message_doc["sender_id"]),
        recipient_id=str(message_doc["recipient_id"])
    )


@router.get("", response_model=List[MessageResponse])
async def get_messages(
    other_user_id: str = Query(..., description="ID of the other user in the conversation"),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: dict = Depends(get_current_user)
):
    """Get messages from a conversation with another user"""
    # Validate other_user_id
    if not ObjectId.is_valid(other_user_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID"
        )
    
    other_user_id_obj = ObjectId(other_user_id)
    current_user_id_obj = ObjectId(current_user["_id"])
    
    # Fetch messages where current user is either sender or recipient with the other user
    # This gets the conversation between the two users
    query = {
        "$or": [
            {
                "sender_id": current_user_id_obj,
                "recipient_id": other_user_id_obj
            },
            {
                "sender_id": other_user_id_obj,
                "recipient_id": current_user_id_obj
            }
        ]
    }
    
    # Fetch messages from database, sorted by timestamp descending
    cursor = db_module.database.messages.find(query).sort("timestamp", -1).limit(limit)
    messages = await cursor.to_list(length=limit)
    
    # Decrypt and format messages
    decrypted_messages = []
    for msg in reversed(messages):  # Reverse to show oldest first
        try:
            # Handle MongoDB Binary type if present
            ciphertext = msg["content_encrypted"]
            nonce = msg["nonce"]
            auth_tag = msg["auth_tag"]
            
            # Convert Binary to bytes if needed
            if isinstance(ciphertext, Binary):
                ciphertext = ciphertext.as_bytes()
            if isinstance(nonce, Binary):
                nonce = nonce.as_bytes()
            if isinstance(auth_tag, Binary):
                auth_tag = auth_tag.as_bytes()
            
            decrypted_content = decrypt_message(ciphertext, nonce, auth_tag)
            decrypted_messages.append(MessageResponse(
                id=str(msg["_id"]),
                username=msg["sender_username"],
                content=decrypted_content,
                timestamp=msg["timestamp"],
                sender_id=str(msg["sender_id"]),
                recipient_id=str(msg["recipient_id"])
            ))
        except Exception as e:
            # If decryption fails, skip the message (or log error)
            print(f"Failed to decrypt message {msg['_id']}: {e}")
            continue
    
    return decrypted_messages

