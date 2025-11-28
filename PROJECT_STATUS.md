# Current Project Status

## A. Tech Stack / Setup

### Backend
- **Framework**: FastAPI (Python)
- **Database**: MongoDB (using Motor for async operations)
- **Server**: Uvicorn ASGI server
- **Authentication**: JWT tokens (stored in httpOnly cookies)
- **Rate Limiting**: slowapi
- **Dependencies**: See `backend/requirements.txt`

### Frontend
- **Framework**: React 18.2.0
- **Language**: TypeScript
- **Build Tool**: Vite 5.0.8
- **Routing**: React Router DOM 6.20.0
- **HTTP Client**: Axios 1.6.2
- **No UI Framework**: Custom CSS (dark mode theme)

### Connection Type
**Both REST APIs and WebSockets:**
- **REST APIs**: Used for authentication, fetching messages, sending messages, managing message requests
- **WebSockets**: Used for real-time message delivery (instant notifications when messages are sent)

**WebSocket Endpoint**: `/ws/{user_id}?token={jwt_token}`

---

## B. How Messages Work (Flow)

### Message Flow
```
User A → POST /messages (REST API) → Server stores in MongoDB → 
Server sends via WebSocket to User B → User B receives instantly
```

**No P2P**: All communication goes through the server. Users never communicate directly.

### Message Types Supported
- **1-to-1 chats only** (no group chats)
- **Text messages only** (no file attachments, images, PDFs, etc.)

### Message Request System
- First message between two users creates a **message request** (pending state)
- Recipient can **accept** or **decline** the request
- Once accepted, future messages go directly to the conversation
- Message requests are stored in `message_requests` collection
- Regular messages are stored in `messages` collection

### Database Collections
- `users`: User accounts (username, password_hash, phone_number, etc.)
- `messages`: Accepted messages between users
- `message_requests`: Pending message requests

---

## C. Current Security / Encryption

### Transport Security
- **HTTPS/TLS**: Recommended for production (currently using HTTP in development)
- **CORS**: Configured for specific origins

### Message Storage
- **Plaintext in Database**: Messages are stored as plaintext in MongoDB
- **No encryption at rest**: The `content` field in messages is stored directly without encryption
- **No end-to-end encryption (E2EE)**: The server can read all messages

### Authentication Security
- **Password Hashing**: bcrypt (via passlib)
- **JWT Tokens**: HS256 algorithm, stored in httpOnly cookies
- **Rate Limiting**: Applied to login/register endpoints

### What Was Removed
- **Post-quantum encryption**: Previously implemented but removed per user request
- **AES-GCM encryption**: Previously used but removed
- **Key management**: Previously had per-user encryption keys, all removed

**Current State**: Messages are completely unencrypted. Only transport layer security (HTTPS) would protect messages in transit, but messages are readable by anyone with database access.

---

## D. Login, Users, and Keys

### User Authentication
- **Method**: Username + Password
- **Registration**: Username, password, area_code, phone_number
- **Password Requirements**: 
  - Minimum 8 characters
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one digit
  - At least one special character (including underscore, dash, etc.)

### Token Management
- **JWT Tokens**: Created on login
- **Storage**: httpOnly cookies (secure, not accessible via JavaScript)
- **Expiration**: 30 minutes (configurable via `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`)
- **Algorithm**: HS256
- **Secret**: Stored in `.env` file as `JWT_SECRET` (must be at least 32 characters)

### Per-User Keys
- **No crypto keys**: No per-user encryption keys currently
- **No key pairs**: No public/private key pairs
- **No key management**: All key-related code was removed

### User Data Stored
```javascript
{
  username: string,
  password_hash: string (bcrypt),
  area_code: string,
  phone_number: string,
  full_phone_number: string,
  created_at: datetime
}
```

---

## E. API Endpoints

### Authentication (`/auth`)
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login (sets JWT cookie)
- `POST /auth/logout` - Logout (clears cookie)
- `GET /auth/me` - Get current user info
- `GET /auth/ws-token` - Get WebSocket authentication token
- `GET /messages/conversations` - Get users you've chatted with

### Messages (`/messages`)
- `POST /messages` - Send a message
- `GET /messages?other_user_id={id}` - Get conversation messages
- `GET /messages/requests` - Get pending message requests
- `POST /messages/requests/{id}/action` - Accept/decline request

### WebSocket (`/ws/{user_id}`)
- Real-time message delivery
- Requires JWT token in query params
- Sends `new_message` and `new_request` events

---

## F. Current Limitations

1. **No encryption**: Messages stored in plaintext
2. **No file attachments**: Text only
3. **No group chats**: 1-to-1 only
4. **No message editing/deletion**: Messages are immutable once sent
5. **No read receipts**: No "seen" indicators
6. **No typing indicators**: No "user is typing..." feature
7. **No message search**: Can't search through message history
8. **No user profiles**: Basic username only, no avatars or status

---

## G. Environment Variables

### Backend (`.env` file)
```env
MONGO_URL=mongodb://localhost:27017
MONGO_DB_NAME=messaging_app
JWT_SECRET=your-super-secret-jwt-key-at-least-32-characters-long
```

### Frontend (optional `.env` file)
```env
VITE_API_URL=http://localhost:8000
```

---

## H. Development Status

✅ **Working:**
- User registration and login
- Sending messages
- Message requests (accept/decline)
- Real-time WebSocket delivery
- Conversation list (shows users you've chatted with)

⚠️ **Issues:**
- WebSocket real-time updates may need browser refresh in some cases (closure issue was fixed but may need testing)

🔧 **Removed:**
- Post-quantum encryption
- Message encryption at rest
- Per-user encryption keys

