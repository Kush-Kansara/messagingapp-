from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException
from typing import Dict, Set
from app.auth import get_current_user_websocket
from app import database as db_module
from bson import ObjectId
import json

router = APIRouter()

# Store active WebSocket connections: {user_id: WebSocket}
active_connections: Dict[str, WebSocket] = {}


@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """WebSocket endpoint for real-time messaging"""
    await websocket.accept()
    
    # Verify user authentication via query params
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008, reason="Authentication required")
        return
    
    # Verify the user_id matches the authenticated user
    try:
        current_user = await get_current_user_websocket(token)
        if str(current_user["_id"]) != user_id:
            await websocket.close(code=1008, reason="Invalid user")
            return
    except HTTPException:
        await websocket.close(code=1008, reason="Authentication failed")
        return
    except Exception as e:
        await websocket.close(code=1008, reason=f"Authentication error: {str(e)}")
        return
    
    # Store connection
    user_id_str = str(current_user["_id"])
    active_connections[user_id_str] = websocket
    print(f"[WEBSOCKET] User {user_id_str} ({current_user['username']}) connected. Total connections: {len(active_connections)}")
    
    try:
        # Send connection confirmation
        await websocket.send_json({
            "type": "connected",
            "message": "WebSocket connected"
        })
        print(f"[WEBSOCKET] Sent connection confirmation to {user_id_str}")
        
        # Keep connection alive and handle incoming messages
        while True:
            data = await websocket.receive_text()
            try:
                message_data = json.loads(data)
                # Handle ping/pong for keepalive
                if message_data.get("type") == "ping":
                    await websocket.send_json({"type": "pong"})
            except json.JSONDecodeError:
                pass  # Ignore invalid JSON
                
    except WebSocketDisconnect:
        print(f"[WEBSOCKET] User {user_id_str} disconnected normally")
    except Exception as e:
        print(f"[WEBSOCKET] Error in WebSocket connection for {user_id_str}: {e}")
    finally:
        # Remove connection when user disconnects
        if user_id_str in active_connections:
            del active_connections[user_id_str]
            print(f"[WEBSOCKET] Removed connection for {user_id_str}. Remaining connections: {len(active_connections)}")


async def send_message_to_user(recipient_id: str, message_data: dict):
    """Send a message to a specific user via WebSocket"""
    print(f"[WEBSOCKET] Attempting to send message to user {recipient_id}")
    print(f"[WEBSOCKET] Active connections: {list(active_connections.keys())}")
    
    if recipient_id in active_connections:
        try:
            websocket = active_connections[recipient_id]
            payload = {
                "type": "new_message",
                "message": message_data
            }
            print(f"[WEBSOCKET] Sending message to {recipient_id}: {payload}")
            await websocket.send_json(payload)
            print(f"[WEBSOCKET] Message sent successfully to {recipient_id}")
            return True
        except Exception as e:
            print(f"[WEBSOCKET] Error sending message to {recipient_id}: {e}")
            # Connection might be dead, remove it
            if recipient_id in active_connections:
                del active_connections[recipient_id]
            return False
    else:
        print(f"[WEBSOCKET] User {recipient_id} is not connected (not in active_connections)")
    return False


async def send_message_request_to_user(recipient_id: str, request_data: dict):
    """Send a message request notification to a user via WebSocket"""
    print(f"[WEBSOCKET] Attempting to send request to user {recipient_id}")
    print(f"[WEBSOCKET] Active connections: {list(active_connections.keys())}")
    
    if recipient_id in active_connections:
        try:
            websocket = active_connections[recipient_id]
            payload = {
                "type": "new_request",
                "request": request_data
            }
            print(f"[WEBSOCKET] Sending request to {recipient_id}: {payload}")
            await websocket.send_json(payload)
            print(f"[WEBSOCKET] Request sent successfully to {recipient_id}")
            return True
        except Exception as e:
            print(f"[WEBSOCKET] Error sending request to {recipient_id}: {e}")
            if recipient_id in active_connections:
                del active_connections[recipient_id]
            return False
    else:
        print(f"[WEBSOCKET] User {recipient_id} is not connected (not in active_connections)")
    return False

