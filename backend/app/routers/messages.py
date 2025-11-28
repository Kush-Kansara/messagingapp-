from fastapi import APIRouter, HTTPException, status, Depends, Query
from datetime import datetime
from typing import List
from app.models import MessageCreate, MessageResponse, MessageRequestResponse, MessageRequestAction, UserResponse
from app.auth import get_current_user
from app import database as db_module
from app.pq_transport import decrypt_aes_gcm
from app.session_manager import get_session_key
from bson import ObjectId
import base64

router = APIRouter(prefix="/messages", tags=["messages"])


@router.post("", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    message_data: MessageCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Send a message to a specific user.
    
    Supports both encrypted and plaintext messages:
    - Encrypted: { recipient_id, nonce, ciphertext } (new format)
    - Plaintext: { recipient_id, content } (backward compatibility)
    
    If encrypted, the server decrypts using the user's session key
    and stores plaintext in MongoDB.
    """
    user_id = str(current_user["_id"])
    
    # Decrypt message if it's encrypted (new PQ transport security)
    if message_data.is_encrypted():
        # Get user's session key (established during PQ handshake)
        session_key = get_session_key(user_id)
        if session_key is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No session key found. Please perform PQ handshake first."
            )
        
        try:
            # Decode base64 nonce and ciphertext
            nonce = base64.b64decode(message_data.nonce)
            ciphertext = base64.b64decode(message_data.ciphertext)
            
            # Decrypt using AES-GCM with the session key
            # This recovers the plaintext message content
            plaintext_content = decrypt_aes_gcm(session_key, nonce, ciphertext)
            print(f"[PQ] Decrypted message from user {current_user['username']}")
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to decrypt message: {str(e)}"
            )
    else:
        # Plaintext message (backward compatibility)
        plaintext_content = message_data.content
        if not plaintext_content or not plaintext_content.strip():
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
    
    # Check if users have previously messaged each other
    # If not, create a message request instead of a direct message
    current_user_id_obj = ObjectId(current_user["_id"])
    existing_conversation = await db_module.database.messages.find_one({
        "$or": [
            {
                "sender_id": current_user_id_obj,
                "recipient_id": recipient_id
            },
            {
                "sender_id": recipient_id,
                "recipient_id": current_user_id_obj
            }
        ]
    })
    
    # If no existing conversation, create a message request
    if not existing_conversation:
        # Create message request document (plaintext)
        request_doc = {
            "sender_id": ObjectId(current_user["_id"]),
            "sender_username": current_user["username"],
            "recipient_id": recipient_id,
            "recipient_username": recipient["username"],
            "content": plaintext_content,  # Store plaintext (decrypted if encrypted)
            "status": "pending",
            "timestamp": datetime.utcnow()
        }
        
        # Insert message request
        result = await db_module.database.message_requests.insert_one(request_doc)
        
        print(f"[MESSAGE_REQUEST] Created request: ID={result.inserted_id}, From={current_user['username']}, To={recipient['username']}")
        
        # Send real-time notification via WebSocket
        from app.routers.websocket import send_message_request_to_user
        request_response = MessageRequestResponse(
            id=str(result.inserted_id),
            sender_id=str(current_user["_id"]),
            sender_username=current_user["username"],
            recipient_id=str(recipient_id),
            content=message_data.content,
            timestamp=request_doc["timestamp"],
            status="pending"
        )
        # Convert to dict and ensure timestamp is ISO string for JSON serialization
        request_dict = request_response.dict()
        if isinstance(request_dict.get("timestamp"), datetime):
            request_dict["timestamp"] = request_dict["timestamp"].isoformat()
        await send_message_request_to_user(str(recipient_id), request_dict)
        
        return MessageResponse(
            id=str(result.inserted_id),
            username=current_user["username"],
            content=plaintext_content,
            timestamp=request_doc["timestamp"],
            sender_id=str(current_user["_id"]),
            recipient_id=str(recipient_id)
        )
    
    # Create message document (plaintext - decrypted from encrypted transport)
    message_doc = {
        "sender_id": ObjectId(current_user["_id"]),
        "sender_username": current_user["username"],
        "recipient_id": recipient_id,
        "recipient_username": recipient["username"],
        "content": plaintext_content,  # Store plaintext (decrypted if encrypted)
        "timestamp": datetime.utcnow()
    }
    
    # Insert message
    result = await db_module.database.messages.insert_one(message_doc)
    message_doc["_id"] = result.inserted_id
    
    print(f"Message sent: ID={message_doc['_id']}, From={current_user['username']}, To={recipient['username']}")
    
    # Send real-time notification via WebSocket
    from app.routers.websocket import send_message_to_user
    message_response = MessageResponse(
        id=str(message_doc["_id"]),
        username=message_doc["sender_username"],
        content=plaintext_content,
        timestamp=message_doc["timestamp"],
        sender_id=str(message_doc["sender_id"]),
        recipient_id=str(message_doc["recipient_id"])
    )
    # Convert to dict and ensure timestamp is ISO string for JSON serialization
    message_dict = message_response.dict()
    if isinstance(message_dict.get("timestamp"), datetime):
        message_dict["timestamp"] = message_dict["timestamp"].isoformat()
    await send_message_to_user(str(recipient_id), message_dict)
    
    # Return message for response
    return message_response


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
    
    # Debug: Log how many messages were found
    print(f"[GET_MESSAGES] Found {len(messages)} messages for conversation between {current_user['username']} (ID: {current_user['_id']}) and user {other_user_id}")
    
    # Return messages (plaintext - no decryption needed)
    message_responses = []
    for msg in reversed(messages):  # Reverse to show oldest first
        # Get content - check both 'content' (new plaintext) and 'content_plaintext' (old format) for backward compatibility
        content = msg.get("content") or msg.get("content_plaintext", "[Message content unavailable]")
        
        message_responses.append(MessageResponse(
            id=str(msg["_id"]),
            username=msg["sender_username"],
            content=content,
            timestamp=msg["timestamp"],
            sender_id=str(msg["sender_id"]),
            recipient_id=str(msg["recipient_id"])
        ))
    
    print(f"[GET_MESSAGES] Returning {len(message_responses)} messages")
    return message_responses


@router.get("/requests", response_model=List[MessageRequestResponse])
async def get_message_requests(
    current_user: dict = Depends(get_current_user)
):
    """Get pending message requests for the current user"""
    current_user_id_obj = ObjectId(current_user["_id"])
    
    # Find all pending requests for current user (as recipient)
    cursor = db_module.database.message_requests.find({
        "recipient_id": current_user_id_obj,
        "status": "pending"
    }).sort("timestamp", -1)
    
    requests = await cursor.to_list(length=100)
    
    # If no requests found, return empty list
    if not requests:
        return []
    
    # Return requests (plaintext - no decryption needed)
    request_responses = []
    for req in requests:
        # Get content - check both 'content' (new plaintext) and 'content_plaintext' (old format) for backward compatibility
        content = req.get("content") or req.get("content_plaintext", "[Message content unavailable]")
        
        request_responses.append(MessageRequestResponse(
            id=str(req["_id"]),
            sender_id=str(req["sender_id"]),
            sender_username=req["sender_username"],
            recipient_id=str(req["recipient_id"]),
            content=content,
            timestamp=req["timestamp"],
            status=req["status"]
        ))
    
    return request_responses


@router.post("/requests/{request_id}/action")
async def handle_message_request(
    request_id: str,
    action_data: MessageRequestAction,
    current_user: dict = Depends(get_current_user)
):
    """Accept or decline a message request"""
    if not ObjectId.is_valid(request_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid request ID"
        )
    
    if action_data.action not in ["accept", "decline"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Action must be 'accept' or 'decline'"
        )
    
    request_id_obj = ObjectId(request_id)
    current_user_id_obj = ObjectId(current_user["_id"])
    
    # Find the request
    request = await db_module.database.message_requests.find_one({
        "_id": request_id_obj,
        "recipient_id": current_user_id_obj,
        "status": "pending"
    })
    
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message request not found or already processed"
        )
    
    if action_data.action == "accept":
        # Convert request to a regular message (plaintext)
        # Get content - check both 'content' (new plaintext) and 'content_plaintext' (old format) for backward compatibility
        content = request.get("content") or request.get("content_plaintext", "")
        
        message_doc = {
            "sender_id": request["sender_id"],
            "sender_username": request["sender_username"],
            "recipient_id": request["recipient_id"],
            "recipient_username": request["recipient_username"],
            "content": content,  # Store plaintext
            "timestamp": request["timestamp"]
        }
        
        # Insert as regular message
        await db_module.database.messages.insert_one(message_doc)
        
        # Update request status
        await db_module.database.message_requests.update_one(
            {"_id": request_id_obj},
            {"$set": {"status": "accepted"}}
        )
        
        return {"message": "Message request accepted", "status": "accepted"}
    
    else:  # decline
        # Update request status
        await db_module.database.message_requests.update_one(
            {"_id": request_id_obj},
            {"$set": {"status": "declined"}}
        )
        
        return {"message": "Message request declined", "status": "declined"}


@router.get("/conversations", response_model=List[UserResponse])
async def get_conversation_partners(
    current_user: dict = Depends(get_current_user)
):
    """Get list of users you've had conversations with (not all users)"""
    current_user_id_obj = ObjectId(current_user["_id"])
    
    # Find all unique users you've messaged with (either as sender or recipient)
    # This gets distinct user IDs from messages where you're involved
    pipeline = [
        {
            "$match": {
                "$or": [
                    {"sender_id": current_user_id_obj},
                    {"recipient_id": current_user_id_obj}
                ]
            }
        },
        {
            "$project": {
                "other_user_id": {
                    "$cond": [
                        {"$eq": ["$sender_id", current_user_id_obj]},
                        "$recipient_id",
                        "$sender_id"
                    ]
                }
            }
        },
        {
            "$group": {
                "_id": "$other_user_id"
            }
        }
    ]
    
    # Get distinct user IDs
    distinct_users = await db_module.database.messages.aggregate(pipeline).to_list(length=100)
    user_ids = [ObjectId(item["_id"]) for item in distinct_users]
    
    if not user_ids:
        return []
    
    # Fetch user details
    cursor = db_module.database.users.find({
        "_id": {"$in": user_ids}
    }).sort("username", 1)
    
    users = await cursor.to_list(length=100)
    
    return [
        UserResponse(
            id=str(user["_id"]),
            username=user["username"],
            created_at=user.get("created_at")
        )
        for user in users
    ]

