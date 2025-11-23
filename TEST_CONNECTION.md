# Test MongoDB Connection

## ✅ MongoDB Status
- **MongoDB Service**: RUNNING ✅
- **Port 27017**: LISTENING ✅
- **.env file**: Configured correctly ✅

## Next Steps: Start Your Backend

### 1. Navigate to backend directory:
```powershell
cd C:\Users\xxcbj\Desktop\CS4355\PostQuantumMessagingApp\backend
```

### 2. Create virtual environment (if not exists):
```powershell
python -m venv venv
```

### 3. Activate virtual environment:
```powershell
venv\Scripts\activate
```

### 4. Install dependencies:
```powershell
pip install -r requirements.txt
```

### 5. Start the backend server:
```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 6. Look for success message:
You should see:
```
Connected to MongoDB: messaging_app
Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

If you see "Connected to MongoDB", everything is working! 🎉

### 7. Test the API:
- Open browser: http://localhost:8000/docs
- You should see the API documentation

### 8. Start Frontend (in a new terminal):
```powershell
cd C:\Users\xxcbj\Desktop\CS4355\PostQuantumMessagingApp\frontend
npm install  # if not done already
npm run dev
```

Then open: http://localhost:5173

---

## Troubleshooting

If you see connection errors:
1. Verify MongoDB is still running: `Get-Service MongoDB`
2. Check port 27017: `netstat -ano | findstr ":27017"`
3. Verify .env file has: `MONGO_URL=mongodb://localhost:27017`

