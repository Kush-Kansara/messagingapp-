# Quick Setup Guide for liboqs

## If You Downloaded the Zip File

### Step 1: Extract the Zip
Extract it to a simple location like:
- `C:\liboqs`
- Or `C:\Users\xxcbj\liboqs`

### Step 2: Run the Setup Script

Open PowerShell in the backend directory:

```powershell
cd PostQuantumMessagingApp\backend
.\venv\Scripts\Activate.ps1
powershell -ExecutionPolicy Bypass -File setup_liboqs.ps1
```

The script will:
- Ask where you extracted liboqs
- Set the environment variable
- Test if it works

### Step 3: Verify

```powershell
python verify_pq.py
```

## Manual Setup (If Script Doesn't Work)

### Step 1: Find Your liboqs Path
Where did you extract it? For example:
- `C:\liboqs`
- `C:\Users\xxcbj\Downloads\liboqs`

### Step 2: Set Environment Variable

**Temporary (current session):**
```powershell
$env:LIBOQS_DIR = "C:\liboqs"  # Use your actual path
```

**Permanent:**
1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Click "Environment Variables"
3. Under "User variables", click "New"
4. Name: `LIBOQS_DIR`
5. Value: `C:\liboqs` (your actual path)
6. Click OK, restart terminal

### Step 3: Test

```powershell
python -c "import oqs; print('Working!')"
```

## Common Issues

### "No oqs shared libraries found"
- Make sure `LIBOQS_DIR` is set correctly
- Check that DLL files exist in that directory
- Restart your terminal after setting the variable

### "Module not found"
- Make sure you're in the virtual environment: `.\venv\Scripts\Activate.ps1`
- Make sure liboqs-python is installed: `pip install liboqs-python`

## Need Help?

Tell me:
1. Where you extracted liboqs (full path)
2. What happens when you run the setup script

