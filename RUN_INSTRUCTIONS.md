# How to Run the Messaging App

## Quick Start Guide

### Prerequisites
- **MongoDB** must be running (local or Atlas)
- **Python 3.10+** installed
- **Node.js 18+** installed

---

## Step 1: Start MongoDB

**Option A: Local MongoDB**
- Make sure MongoDB is running on your system
- Default connection: `mongodb://localhost:27017`

**Option B: MongoDB Atlas (Cloud)**
- Use your MongoDB Atlas connection string
- Example: `mongodb+srv://username:password@cluster.mongodb.net/`

---

## Step 2: Backend Setup

1. **Open a terminal** and navigate to the backend directory:
   ```powershell
   cd PostQuantumMessagingApp\backend
   ```

2. **Activate the virtual environment**:
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```
   You should see `(venv)` in your prompt.

3. **Create `.env` file** (if it doesn't exist):
   ```powershell
   # Create the file
   New-Item .env -ItemType File
   ```

4. **Edit `.env` file** with these contents:
   ```env
   MONGO_URL=mongodb://localhost:27017
   MONGO_DB_NAME=messaging_app
   JWT_SECRET=your-super-secret-jwt-key-change-this-to-something-random-and-long
   ```
   
   **If using MongoDB Atlas**, replace `MONGO_URL`:
   ```env
   MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/
   MONGO_DB_NAME=messaging_app
   JWT_SECRET=your-super-secret-jwt-key-change-this-to-something-random-and-long
   ```
   
   ⚠️ **Important**: Make sure `JWT_SECRET` is at least 32 characters long!

5. **Start the backend server**:
   ```powershell
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
   
   You should see:
   ```
   INFO:     Uvicorn running on http://0.0.0.0:8000
   INFO:     Application startup complete.
   ```
   
   ✅ Backend is now running at: **http://localhost:8000**
   📚 API docs available at: **http://localhost:8000/docs**

---

## Step 3: Frontend Setup

1. **Open a NEW terminal** (keep the backend running) and navigate to frontend:
   ```powershell
   cd PostQuantumMessagingApp\frontend
   ```

2. **Install dependencies** (if not already installed):
   ```powershell
   npm install
   ```

3. **Start the frontend development server**:
   ```powershell
   npm run dev
   ```
   
   You should see:
   ```
   VITE v5.x.x  ready in xxx ms
   
   ➜  Local:   http://localhost:5173/
   ➜  Network: use --host to expose
   ```
   
   ✅ Frontend is now running at: **http://localhost:5173**

---

## Step 4: Use the App

1. **Open your browser** and go to: **http://localhost:5173**

2. **Register a new user**:
   - Click "Register"
   - Enter username, password, area code, and phone number
   - Click "Register"

3. **Open another browser window** (or incognito):
   - Register a second user

4. **Login with both users**:
   - Each user in their own browser window

5. **Start chatting**:
   - Select a user from the sidebar
   - Type a message and send
   - The other user will see it as a message request (first message)
   - After accepting, you can chat normally!

---

## Troubleshooting

### Backend Issues

**"Connection refused" or MongoDB errors:**
- Make sure MongoDB is running
- Check your `MONGO_URL` in `.env` is correct
- For Atlas, make sure your IP is whitelisted

**"JWT_SECRET must be at least 32 characters":**
- Update your `.env` file with a longer JWT_SECRET (at least 32 characters)

**Port 8000 already in use:**
- Change the port: `uvicorn app.main:app --reload --port 8001`
- Update frontend `.env` if you have one: `VITE_API_URL=http://localhost:8001`

### Frontend Issues

**"Cannot connect to backend":**
- Make sure backend is running on port 8000
- Check browser console for CORS errors
- Verify `VITE_API_URL` in frontend `.env` (if you created one)

**"npm install" fails:**
- Make sure Node.js 18+ is installed: `node --version`
- Try deleting `node_modules` and `package-lock.json`, then run `npm install` again

---

## Stopping the Servers

- **Backend**: Press `Ctrl+C` in the backend terminal
- **Frontend**: Press `Ctrl+C` in the frontend terminal

---

## Summary

**Backend Terminal:**
```powershell
cd PostQuantumMessagingApp\backend
.\venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend Terminal:**
```powershell
cd PostQuantumMessagingApp\frontend
npm run dev
```

**Then open:** http://localhost:5173 in your browser!

