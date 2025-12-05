"""
Demo setup script to create sample users and messages for demonstration purposes.
This script creates demo users and optionally some sample messages.

Usage:
    python setup_demo.py
"""

import asyncio
import sys
from datetime import datetime, timedelta
from app.database import connect_to_mongo, close_mongo_connection
from app import database as db_module
from app.auth import get_password_hash
from bson import ObjectId


# Demo users to create
DEMO_USERS = [
    {
        "username": "alice",
        "password": "Password123!",
        "area_code": "+1",
        "phone_number": "5550100"
    },
    {
        "username": "bob",
        "password": "Password123!",
        "area_code": "+1",
        "phone_number": "5550101"
    },
    {
        "username": "charlie",
        "password": "Password123!",
        "area_code": "+1",
        "phone_number": "5550102"
    }
]


async def create_demo_users():
    """Create demo users in the database"""
    print("Connecting to database...")
    await connect_to_mongo()
    
    if db_module.database is None:
        print("Error: Database not initialized")
        return False
    
    try:
        created_count = 0
        skipped_count = 0
        
        for user_data in DEMO_USERS:
            # Check if user already exists
            existing_user = await db_module.database.users.find_one({
                "username": user_data["username"]
            })
            
            if existing_user:
                print(f"  ⚠️  User '{user_data['username']}' already exists, skipping...")
                skipped_count += 1
                continue
            
            # Check if phone number is already taken
            full_phone = f"{user_data['area_code']}{user_data['phone_number']}"
            existing_phone = await db_module.database.users.find_one({
                "full_phone_number": full_phone
            })
            
            if existing_phone:
                print(f"  ⚠️  Phone number {full_phone} already taken, skipping '{user_data['username']}'...")
                skipped_count += 1
                continue
            
            # Hash password
            password_hash = get_password_hash(user_data["password"])
            
            # Create user document
            user_doc = {
                "username": user_data["username"],
                "password_hash": password_hash,
                "area_code": user_data["area_code"],
                "phone_number": user_data["phone_number"],
                "full_phone_number": full_phone,
                "created_at": datetime.utcnow()
            }
            
            # Insert user
            result = await db_module.database.users.insert_one(user_doc)
            print(f"  ✅ Created user: {user_data['username']} (ID: {result.inserted_id})")
            created_count += 1
        
        print(f"\n[SUCCESS] Created {created_count} demo users, skipped {skipped_count} existing users")
        print("\nDemo User Credentials:")
        print("=" * 50)
        for user_data in DEMO_USERS:
            print(f"  Username: {user_data['username']}")
            print(f"  Password: {user_data['password']}")
            print(f"  Phone: {user_data['area_code']}{user_data['phone_number']}")
            print()
        
        return True
        
    except Exception as e:
        print(f"Error creating demo users: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        await close_mongo_connection()


async def create_sample_messages():
    """Create sample messages between demo users (optional)"""
    print("\nCreating sample messages...")
    await connect_to_mongo()
    
    if db_module.database is None:
        print("Error: Database not initialized")
        return False
    
    try:
        # Get demo users
        alice = await db_module.database.users.find_one({"username": "alice"})
        bob = await db_module.database.users.find_one({"username": "bob"})
        
        if not alice or not bob:
            print("  ⚠️  Demo users not found. Create users first.")
            return False
        
        # Sample messages (plaintext - will be encrypted by the app when sent)
        sample_messages = [
            {
                "sender": alice["_id"],
                "recipient": bob["_id"],
                "content": "Hi Bob! This is Alice. Want to chat?",
                "timestamp": datetime.utcnow() - timedelta(minutes=10)
            },
            {
                "sender": bob["_id"],
                "recipient": alice["_id"],
                "content": "Hey Alice! Sure, let's chat!",
                "timestamp": datetime.utcnow() - timedelta(minutes=9)
            },
            {
                "sender": alice["_id"],
                "recipient": bob["_id"],
                "content": "Great! This messaging app uses post-quantum cryptography.",
                "timestamp": datetime.utcnow() - timedelta(minutes=8)
            },
            {
                "sender": bob["_id"],
                "recipient": alice["_id"],
                "content": "That's awesome! It uses CRYSTALS-Kyber, right?",
                "timestamp": datetime.utcnow() - timedelta(minutes=7)
            },
            {
                "sender": alice["_id"],
                "recipient": bob["_id"],
                "content": "Yes! It's a NIST-selected post-quantum algorithm.",
                "timestamp": datetime.utcnow() - timedelta(minutes=6)
            }
        ]
        
        # Note: In the actual app, messages are encrypted with AES-GCM
        # For demo purposes, we'll create them as plaintext in the database
        # In production, you'd need to encrypt them properly
        
        print("  ⚠️  Note: Sample messages feature is not fully implemented.")
        print("  ⚠️  Messages should be created through the app to ensure proper encryption.")
        print("  ⚠️  Skipping sample message creation.")
        
        return True
        
    except Exception as e:
        print(f"Error creating sample messages: {e}")
        return False
    finally:
        await close_mongo_connection()


async def main():
    """Main function"""
    print("=" * 60)
    print("Post-Quantum Messaging App - Demo Setup")
    print("=" * 60)
    print()
    
    # Create demo users
    success = await create_demo_users()
    
    if not success:
        print("\n[ERROR] Failed to create demo users")
        sys.exit(1)
    
    # Optionally create sample messages
    # Uncomment the line below if you want to create sample messages
    # await create_sample_messages()
    
    print("\n" + "=" * 60)
    print("Demo setup complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Start the backend server: .\\start_server.ps1")
    print("2. Start the frontend: cd ..\\frontend && npm run dev")
    print("3. Open http://localhost:5173 in your browser")
    print("4. Login with one of the demo users above")
    print("\nFor a full demo guide, see DEMO_GUIDE.md")


if __name__ == "__main__":
    asyncio.run(main())


