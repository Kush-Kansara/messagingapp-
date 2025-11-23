# Messaging App

A simple, production-ready full-stack messaging application with encrypted message storage.

## Features

- **User Authentication**: Sign up and login with username/password
- **JWT-based Auth**: Secure token-based authentication
- **Encrypted Messages**: Messages are encrypted at rest using AES-256-GCM
- **One-to-One Messaging**: Private conversations between users
- **Real-time Updates**: Polling-based message updates (every 3 seconds)

## Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **MongoDB** - NoSQL database
- **Motor** - Async MongoDB driver
- **JWT** - Token-based authentication
- **Bcrypt** - Password hashing
- **Cryptography** - AES-GCM encryption

### Frontend
- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool
- **React Router** - Client-side routing
- **Axios** - HTTP client

## Project Structure

```
.
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py          # FastAPI app entry point
│   │   ├── config.py        # Configuration settings
│   │   ├── database.py      # MongoDB connection
│   │   ├── models.py        # Pydantic models
│   │   ├── auth.py          # Authentication utilities
│   │   ├── encryption.py    # Message encryption/decryption
│   │   └── routers/
│   │       ├── auth.py      # Auth endpoints
│   │       └── messages.py  # Message endpoints
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── context/         # Auth context
│   │   ├── services/        # API client
│   │   ├── types/           # TypeScript types
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── nginx.conf
└── README.md
```

## Prerequisites

- Python 3.11+ and Node.js 18+
- MongoDB

## Quick Start

### Step 1: Install Prerequisites

1. **Install Python 3.11+**: Download from [python.org](https://www.python.org/downloads/)
2. **Install Node.js 18+**: Download from [nodejs.org](https://nodejs.org/)
3. **Install MongoDB**: 
   - **Option A (Local)**: Download from [mongodb.com](https://www.mongodb.com/try/download/community)
   - **Option B (Cloud)**: Use [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (free tier available)

### Step 2: Start MongoDB

**If using local MongoDB:**
- **Windows**: MongoDB should start automatically as a service, or run `mongod` from command prompt
- **macOS/Linux**: Run `mongod` or start MongoDB service

**If using MongoDB Atlas:**
- Create a free cluster and get your connection string
- It will look like: `mongodb+srv://username:password@cluster.mongodb.net/`

### Step 3: Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd PostQuantumMessagingApp/backend
   ```

2. **Create a virtual environment**:
   ```bash
   # Windows
   python -m venv venv
   venv\Scripts\activate
   
   # macOS/Linux
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Generate encryption key**:
   ```bash
   # From the project root directory
   cd ..
   python generate_key.py
   ```
   Copy the generated key (you'll need it in the next step).

5. **Create `.env` file** in the `backend` directory:
   ```bash
   cd backend
   # Create .env file manually or use:
   # Windows (PowerShell)
   New-Item .env
   # macOS/Linux
   touch .env
   ```

6. **Edit `.env` file** with the following content:
   ```env
   MONGO_URL=mongodb://localhost:27017
   MONGO_DB_NAME=messaging_app
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   APP_ENCRYPTION_KEY=<paste-the-generated-key-from-step-4>
   ```
   
   **If using MongoDB Atlas**, replace `MONGO_URL` with your Atlas connection string:
   ```env
   MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/
   ```

7. **Run the backend**:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
   
   You should see: `Application startup complete`
   Backend will be running at: http://localhost:8000
   API docs available at: http://localhost:8000/docs

### Step 4: Frontend Setup

1. **Open a new terminal** and navigate to frontend directory:
   ```bash
   cd PostQuantumMessagingApp/frontend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Create `.env` file** (optional, defaults to http://localhost:8000):
   ```bash
   # Windows (PowerShell)
   New-Item .env
   # macOS/Linux
   touch .env
   ```
   
   Add to `.env`:
   ```env
   VITE_API_URL=http://localhost:8000
   ```

4. **Run the development server**:
   ```bash
   npm run dev
   ```
   
   You should see: `Local: http://localhost:5173`

5. **Access the app**: Open http://localhost:5173 in your browser

### Step 5: Create Users and Start Chatting

1. **Register a new user**: Click "Register" and create an account
2. **Open another browser/incognito window**: Register a second user
3. **Login with both users**: Each in their own browser window
4. **Start chatting**: Select a user from the sidebar to start a conversation!

## Environment Variables

### Backend

| Variable | Description | Default |
|----------|-------------|---------|
| `MONGO_URL` | MongoDB connection string | `mongodb://localhost:27017` |
| `MONGO_DB_NAME` | Database name | `messaging_app` |
| `JWT_SECRET` | Secret key for JWT signing | Required |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiration time | `30` |
| `APP_ENCRYPTION_KEY` | 32-byte encryption key (base64/hex) | Required |
| `HOST` | Server host | `0.0.0.0` |
| `PORT` | Server port | `8000` |

### Frontend

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API URL | `http://localhost:8000` |

## API Endpoints

### Authentication

- `POST /auth/register` - Register a new user
  ```json
  {
    "username": "user123",
    "password": "password123"
  }
  ```

- `POST /auth/login` - Login and get JWT token
  ```json
  {
    "username": "user123",
    "password": "password123"
  }
  ```

- `GET /auth/me` - Get current user info (requires authentication)

### Messages

- `POST /messages` - Send a message to a specific user (requires authentication)
  ```json
  {
    "content": "Hello!",
    "recipient_id": "user_id_here"
  }
  ```

- `GET /messages?other_user_id=<user_id>&limit=50` - Get messages from a conversation (requires authentication)

### Users

- `GET /auth/users` - Get list of all users (excluding current user, requires authentication)

## Security Features

1. **Password Hashing**: Passwords are hashed using bcrypt before storage
2. **JWT Authentication**: Secure token-based authentication
3. **Message Encryption**: Messages are encrypted at rest using AES-256-GCM
4. **CORS Protection**: Configured CORS middleware for frontend

## Deployment

### Deploy to Render / Railway / Fly.io

1. **Backend Deployment**:
   - Set environment variables in your hosting platform
   - Use MongoDB Atlas or a managed MongoDB service
   - Update `MONGO_URL` to your MongoDB connection string
   - Set `APP_ENCRYPTION_KEY` and `JWT_SECRET`

2. **Frontend Deployment**:
   - Build the frontend: `npm run build`
   - Deploy the `dist` folder to a static hosting service
   - Set `VITE_API_URL` to your backend URL

### Example: Render Deployment

**Backend Service**:
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Environment Variables: Set all required variables

**Frontend Service**:
- Build Command: `npm install && npm run build`
- Publish Directory: `dist`
- Environment Variables: `VITE_API_URL=https://your-backend.onrender.com`

## Development Notes

- Messages are polled every 3 seconds (can be changed in `Chat.tsx`)
- JWT tokens expire after 30 minutes (configurable)
- Encryption key must be 32 bytes (256 bits) for AES-256
- MongoDB collections: `users` and `messages`
- The app supports one-to-one private messaging between users

## Troubleshooting

1. **Connection refused errors**: Ensure MongoDB is running and accessible
2. **Encryption errors**: Verify `APP_ENCRYPTION_KEY` is a valid 32-byte key
3. **CORS errors**: Check that frontend URL is in backend CORS allowed origins
4. **Token expired**: Login again to get a new token

## License

MIT

