# How to Start MongoDB

## Option 1: MongoDB Atlas (Cloud - Easiest & Free) ⭐ RECOMMENDED

1. **Go to**: https://www.mongodb.com/cloud/atlas/register
2. **Sign up** for a free account
3. **Create a Free Cluster** (M0 - Free tier):
   - Click "Build a Database"
   - Choose "FREE" (M0)
   - Select a region (choose closest to you)
   - Click "Create"
   - Wait 3-5 minutes for cluster to be created

4. **Set up Database Access**:
   - Click "Database Access" in left menu
   - Click "Add New Database User"
   - Choose "Password" authentication
   - Username: `admin` (or your choice)
   - Password: Create a strong password (save it!)
   - Database User Privileges: "Atlas admin" or "Read and write to any database"
   - Click "Add User"

5. **Set up Network Access**:
   - Click "Network Access" in left menu
   - Click "Add IP Address"
   - Click "Allow Access from Anywhere" (for development)
   - Or add your IP: `0.0.0.0/0`
   - Click "Confirm"

6. **Get Connection String**:
   - Click "Database" → "Connect" on your cluster
   - Choose "Connect your application"
   - Copy the connection string (looks like):
     ```
     mongodb+srv://admin:<password>@cluster0.xxxxx.mongodb.net/
     ```
   - Replace `<password>` with your actual password

7. **Update your `.env` file** in `backend/`:
   ```env
   MONGO_URL=mongodb+srv://admin:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/
   MONGO_DB_NAME=messaging_app
   JWT_SECRET=vOm70lM11b63StMgaJj0M2BNly4KRVE0XswLv4GUCXU=
   APP_ENCRYPTION_KEY=vOm70lM11b63StMgaJj0M2BNly4KRVE0XswLv4GUCXU=
   ```

8. **Restart your backend server** - MongoDB is now running in the cloud!

---

## Option 2: Install MongoDB Locally

### Windows Installation:

1. **Download MongoDB Community Server**:
   - Go to: https://www.mongodb.com/try/download/community
   - Version: Latest (7.0+)
   - Platform: Windows
   - Package: MSI
   - Click "Download"

2. **Run the Installer**:
   - Run the downloaded `.msi` file
   - Choose "Complete" installation
   - **IMPORTANT**: Check "Install MongoDB as a Service"
   - Check "Run service as Network Service user"
   - Check "Install MongoDB Compass" (optional GUI tool)
   - Click "Install"

3. **Verify Installation**:
   ```powershell
   # Check if MongoDB service is running
   Get-Service MongoDB
   
   # If it shows "Stopped", start it:
   Start-Service MongoDB
   
   # Verify it's running
   Get-Service MongoDB
   ```

4. **Test Connection**:
   ```powershell
   # Try connecting (if mongosh is installed)
   mongosh
   # Type 'exit' to quit
   ```

5. **Your `.env` file should already be correct**:
   ```env
   MONGO_URL=mongodb://localhost:27017
   ```

---

## Option 3: Use Docker (If you have Docker Desktop)

```powershell
# Start MongoDB in a Docker container
docker run -d -p 27017:27017 --name mongodb mongo:7

# Verify it's running
docker ps

# Check logs if needed
docker logs mongodb
```

Your `.env` file will work as-is with Docker.

---

## Verify MongoDB is Running

After setting up MongoDB (any option), test it:

```powershell
# Check if port 27017 is listening
netstat -ano | findstr ":27017"
```

You should see something like:
```
TCP    0.0.0.0:27017    0.0.0.0:0    LISTENING    <PID>
```

---

## Quick Test

Once MongoDB is running, start your backend:

```powershell
cd PostQuantumMessagingApp\backend
venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

You should see: `Connected to MongoDB: messaging_app`

If you see connection errors, MongoDB is not running or the connection string is wrong.

