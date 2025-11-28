"""
Document Management Router
==========================

This router handles document (HTML pages) storage and retrieval with post-quantum transport security.
Documents are stored in MongoDB and can be uploaded/retrieved using encrypted channels.
"""

from fastapi import APIRouter, HTTPException, status, Depends, Query
from datetime import datetime
from typing import List, Optional
from app.models import (
    DocumentCreate, DocumentUpdate, DocumentResponse, DocumentListItem
)
from app.auth import get_current_user
from app import database as db_module
from app.pq_transport import decrypt_aes_gcm
from app.session_manager import get_session_key
from bson import ObjectId
import base64

router = APIRouter(prefix="/documents", tags=["documents"])


@router.post("", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    document_data: DocumentCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Upload a new HTML document to the server.
    
    Supports both encrypted and plaintext uploads:
    - Encrypted: { title, nonce, ciphertext } (post-quantum transport security)
    - Plaintext: { title, content } (backward compatibility)
    
    If encrypted, the server decrypts using the user's session key
    and stores plaintext HTML in MongoDB.
    """
    user_id = str(current_user["_id"])
    
    # Decrypt document content if it's encrypted (PQ transport security)
    if document_data.is_encrypted():
        # Get user's session key (established during PQ handshake)
        session_key = get_session_key(user_id)
        if session_key is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No session key found. Please perform PQ handshake first."
            )
        
        try:
            # Decode base64 nonce and ciphertext
            nonce = base64.b64decode(document_data.nonce)
            ciphertext = base64.b64decode(document_data.ciphertext)
            
            # Decrypt using AES-GCM with the session key
            # This recovers the plaintext HTML content
            plaintext_content = decrypt_aes_gcm(session_key, nonce, ciphertext)
            print(f"[PQ] Decrypted document from user {current_user['username']}")
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to decrypt document: {str(e)}"
            )
    else:
        # Plaintext document (backward compatibility)
        plaintext_content = document_data.content
        if not plaintext_content or not plaintext_content.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Document content cannot be empty"
            )
    
    # Validate HTML content (basic check)
    if not plaintext_content.strip().lower().startswith('<!doctype') and \
       not plaintext_content.strip().lower().startswith('<html'):
        # Allow partial HTML fragments, but warn
        print(f"[WARNING] Document from {current_user['username']} may not be valid HTML")
    
    # Create document document
    document_doc = {
        "user_id": ObjectId(current_user["_id"]),
        "username": current_user["username"],
        "title": document_data.title,
        "content": plaintext_content,  # Store plaintext HTML (decrypted if encrypted)
        "content_type": "text/html",
        "timestamp": datetime.utcnow(),
        "updated_at": None
    }
    
    # Insert document
    result = await db_module.database.documents.insert_one(document_doc)
    document_doc["_id"] = result.inserted_id
    
    print(f"Document uploaded: ID={document_doc['_id']}, Title={document_data.title}, User={current_user['username']}")
    
    # Return document response
    return DocumentResponse(
        id=str(document_doc["_id"]),
        username=document_doc["username"],
        title=document_doc["title"],
        content=document_doc["content"],
        content_type=document_doc["content_type"],
        timestamp=document_doc["timestamp"],
        updated_at=document_doc.get("updated_at")
    )


@router.get("", response_model=List[DocumentListItem])
async def list_documents(
    limit: int = Query(default=50, ge=1, le=100),
    skip: int = Query(default=0, ge=0),
    current_user: Optional[dict] = Depends(get_current_user)
):
    """
    List all documents in the database.
    
    Returns a list of document metadata (title, author, timestamp) without content.
    Use GET /documents/{document_id} to retrieve full document content.
    """
    # Fetch documents from database, sorted by timestamp descending
    cursor = db_module.database.documents.find({}).sort("timestamp", -1).skip(skip).limit(limit)
    documents = await cursor.to_list(length=limit)
    
    print(f"[LIST_DOCUMENTS] Found {len(documents)} documents")
    
    # Return document list items (metadata only, no content)
    document_list = []
    for doc in documents:
        document_list.append(DocumentListItem(
            id=str(doc["_id"]),
            title=doc["title"],
            username=doc["username"],
            timestamp=doc["timestamp"],
            updated_at=doc.get("updated_at")
        ))
    
    return document_list


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: str,
    current_user: Optional[dict] = Depends(get_current_user)
):
    """
    Get a specific document by ID.
    
    Returns the full document including HTML content.
    No authentication required - documents are publicly readable.
    """
    # Validate document_id
    if not ObjectId.is_valid(document_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid document ID"
        )
    
    document_id_obj = ObjectId(document_id)
    
    # Find document
    document = await db_module.database.documents.find_one({"_id": document_id_obj})
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found"
        )
    
    # Return full document (plaintext HTML)
    return DocumentResponse(
        id=str(document["_id"]),
        username=document["username"],
        title=document["title"],
        content=document["content"],
        content_type=document.get("content_type", "text/html"),
        timestamp=document["timestamp"],
        updated_at=document.get("updated_at")
    )


@router.put("/{document_id}", response_model=DocumentResponse)
async def update_document(
    document_id: str,
    document_data: DocumentUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update an existing document.
    
    Only the document owner can update their documents.
    Supports encrypted updates (post-quantum transport security).
    """
    # Validate document_id
    if not ObjectId.is_valid(document_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid document ID"
        )
    
    document_id_obj = ObjectId(document_id)
    user_id = ObjectId(current_user["_id"])
    
    # Find document
    document = await db_module.database.documents.find_one({"_id": document_id_obj})
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found"
        )
    
    # Check ownership
    if document["user_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update your own documents"
        )
    
    # Decrypt content if encrypted
    update_data = {}
    if document_data.title is not None:
        update_data["title"] = document_data.title
    
    if document_data.is_encrypted():
        # Get user's session key
        session_key = get_session_key(str(user_id))
        if session_key is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No session key found. Please perform PQ handshake first."
            )
        
        try:
            nonce = base64.b64decode(document_data.nonce)
            ciphertext = base64.b64decode(document_data.ciphertext)
            plaintext_content = decrypt_aes_gcm(session_key, nonce, ciphertext)
            update_data["content"] = plaintext_content
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to decrypt document: {str(e)}"
            )
    elif document_data.content is not None:
        update_data["content"] = document_data.content
    
    # Add updated timestamp
    update_data["updated_at"] = datetime.utcnow()
    
    # Update document
    await db_module.database.documents.update_one(
        {"_id": document_id_obj},
        {"$set": update_data}
    )
    
    # Fetch updated document
    updated_document = await db_module.database.documents.find_one({"_id": document_id_obj})
    
    return DocumentResponse(
        id=str(updated_document["_id"]),
        username=updated_document["username"],
        title=updated_document["title"],
        content=updated_document["content"],
        content_type=updated_document.get("content_type", "text/html"),
        timestamp=updated_document["timestamp"],
        updated_at=updated_document.get("updated_at")
    )


@router.delete("/{document_id}")
async def delete_document(
    document_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a document.
    
    Only the document owner can delete their documents.
    """
    # Validate document_id
    if not ObjectId.is_valid(document_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid document ID"
        )
    
    document_id_obj = ObjectId(document_id)
    user_id = ObjectId(current_user["_id"])
    
    # Find document
    document = await db_module.database.documents.find_one({"_id": document_id_obj})
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found"
        )
    
    # Check ownership
    if document["user_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own documents"
        )
    
    # Delete document
    await db_module.database.documents.delete_one({"_id": document_id_obj})
    
    return {"message": "Document deleted successfully"}

