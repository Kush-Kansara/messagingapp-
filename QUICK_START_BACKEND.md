# Quick Start - Backend Server

## Start the Backend Server

### Option 1: Using PowerShell Script (Recommended)

```powershell
cd backend
.\start_server.ps1
```

### Option 2: Manual Start

```powershell
cd backend

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Option 3: Direct Python Command

```powershell
cd backend
.\venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Verify Backend is Running

After starting, you should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
Connected to MongoDB: messaging_app
Application startup complete.
```

## Test Backend

Open in browser: http://localhost:8000

Should see:
```json
{
  "message": "Post-Quantum Secure Document Server API",
  "status": "running"
}
```

## Common Issues

### "Port 8000 already in use"
- Another process is using port 8000
- Change port: `uvicorn app.main:app --reload --port 8001`
- Update frontend `.env`: `VITE_API_URL=http://localhost:8001`

### "MongoDB connection failed"
- Start MongoDB: `Start-Service MongoDB`
- Check `.env` file has correct `MONGO_URL`

### "Module not found"
- Activate virtual environment first
- Install dependencies: `pip install -r requirements.txt`

