# Quick Setup Guide

## Fix MongoDB Connection Error

The error `ECONNREFUSED 127.0.0.1:27019` means MongoDB is not running or not accessible.

### Option 1: Install and Run MongoDB Locally (Recommended for Development)

1. **Download MongoDB Community Server**:
   - Go to: https://www.mongodb.com/try/download/community
   - Select Windows, MSI installer
   - Install with default settings (includes MongoDB as a Windows service)

2. **Verify MongoDB is Running**:
   ```powershell
   # Check if MongoDB service is running
   Get-Service MongoDB
   
   # If not running, start it:
   Start-Service MongoDB
   ```

3. **Create `.env` file** in `backend/` directory:
   ```env
   MONGO_URL=mongodb://localhost:27017
   MONGO_DB_NAME=messaging_app
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   APP_ENCRYPTION_KEY=eZUJ7WX7rb6rfYDhbHDyS/IcOu6pob6LTbEVibTsKR8=
   ```

4. **Test MongoDB Connection**:
   ```powershell
   # Try connecting (should work if MongoDB is running)
   mongosh
   # Type 'exit' to quit
   ```

### Option 2: Use MongoDB Atlas (Cloud - Free Tier)

1. **Sign up for MongoDB Atlas**:
   - Go to: https://www.mongodb.com/cloud/atlas/register
   - Create a free account

2. **Create a Cluster**:
   - Choose "Free" tier (M0)
   - Select a region close to you
   - Wait for cluster to be created (~5 minutes)

3. **Get Connection String**:
   - Click "Connect" on your cluster
   - Choose "Connect your application"
   - Copy the connection string (looks like: `mongodb+srv://username:password@cluster.mongodb.net/`)

4. **Create `.env` file** in `backend/` directory:
   ```env
   MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/
   MONGO_DB_NAME=messaging_app
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   APP_ENCRYPTION_KEY=eZUJ7WX7rb6rfYDhbHDyS/IcOu6pob6LTbEVibTsKR8=
   ```
   Replace `username` and `password` with your Atlas credentials.

### Option 3: Run MongoDB with Docker (If you have Docker)

```powershell
docker run -d -p 27017:27017 --name mongodb mongo:7
```

Then use the same `.env` as Option 1.

## Generate New Encryption Key (if needed)

If you need to generate a new encryption key:

```powershell
cd PostQuantumMessagingApp
python generate_key.py
```

Copy the generated key to your `.env` file.

## Verify Setup

1. **Start Backend**:
   ```powershell
   cd PostQuantumMessagingApp\backend
   venv\Scripts\activate
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **Check for Connection Success**:
   - You should see: `Connected to MongoDB: messaging_app`
   - If you see connection errors, MongoDB is not running or the URL is wrong

3. **Start Frontend** (in another terminal):
   ```powershell
   cd PostQuantumMessagingApp\frontend
   npm run dev
   ```

## Troubleshooting

- **Port 27019 error**: Check if you have an environment variable `MONGO_URL` set to port 27019. Unset it or update it to 27017.
- **MongoDB not found**: Make sure MongoDB is installed and the service is running.
- **Connection refused**: Verify MongoDB is listening on the correct port (27017).

