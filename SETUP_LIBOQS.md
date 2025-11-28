# Setting Up liboqs from Downloaded Zip

## Step-by-Step Instructions

### Step 1: Extract the Zip File

1. Extract the downloaded `liboqs` zip file to a location like:
   ```
   C:\liboqs
   ```
   or
   ```
   C:\Users\xxcbj\liboqs
   ```

2. Make sure the folder structure looks like:
   ```
   C:\liboqs\
   ├── CMakeLists.txt
   ├── src\
   ├── tests\
   └── ... (other files)
   ```

### Step 2: Build liboqs (If Source Code)

If you downloaded the source code zip, you need to build it:

**Prerequisites:**
- Visual Studio Build Tools (or Visual Studio)
- CMake (download from https://cmake.org/download/)
- Git (optional, but helpful)

**Build Steps:**

1. Open PowerShell or Command Prompt as Administrator

2. Navigate to the liboqs directory:
   ```powershell
   cd C:\liboqs
   ```

3. Create a build directory:
   ```powershell
   mkdir build
   cd build
   ```

4. Configure with CMake:
   ```powershell
   cmake .. -G "Visual Studio 17 2022" -A x64
   ```
   (Adjust the Visual Studio version if needed)

5. Build:
   ```powershell
   cmake --build . --config Release
   ```

6. The built libraries will be in:
   ```
   C:\liboqs\build\bin\Release\
   ```

### Step 3: Set Environment Variable

Set the `LIBOQS_DIR` environment variable to point to your liboqs directory:

**Option A: Temporary (Current Session Only)**
```powershell
$env:LIBOQS_DIR = "C:\liboqs\build"  # If you built from source
# OR
$env:LIBOQS_DIR = "C:\liboqs"  # If using pre-built binaries
```

**Option B: Permanent (Recommended)**

1. Open System Properties:
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Or: Right-click "This PC" → Properties → Advanced system settings

2. Click "Environment Variables"

3. Under "User variables" (or "System variables"), click "New"

4. Variable name: `LIBOQS_DIR`
   Variable value: `C:\liboqs\build` (or wherever your liboqs is)

5. Click OK on all dialogs

6. **Restart your terminal/PowerShell** for changes to take effect

### Step 4: Verify Installation

1. Open a NEW PowerShell window (to get the new environment variable)

2. Navigate to your backend:
   ```powershell
   cd C:\Users\xxcbj\Desktop\CS4355\PostQuantumMessagingApp\backend
   ```

3. Activate virtual environment:
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```

4. Test if liboqs works:
   ```powershell
   python -c "import oqs; kem = oqs.KeyEncapsulation('Kyber512'); pub = kem.generate_keypair(); print('SUCCESS: liboqs is working!')"
   ```

5. Run the full verification:
   ```powershell
   python verify_pq.py
   ```

## Troubleshooting

### If you get "No oqs shared libraries found":

1. **Check the path:**
   ```powershell
   echo $env:LIBOQS_DIR
   ```
   Make sure it points to the right directory

2. **Check if libraries exist:**
   - Look for `.dll` files in `C:\liboqs\build\bin\Release\` (Windows)
   - Or `.so` files on Linux, `.dylib` on Mac

3. **Try different paths:**
   - If you built from source: `C:\liboqs\build`
   - If using pre-built: `C:\liboqs` (or wherever you extracted)

### If CMake fails:

- Make sure CMake is installed and in your PATH
- Make sure Visual Studio Build Tools are installed
- Try a different generator: `cmake .. -G "MinGW Makefiles"` (if you have MinGW)

### Alternative: Use Pre-built Binaries

If building is too complex, look for:
- Pre-built Windows binaries on the releases page
- Or use the automatic installer (though it may have the same issue)

## Quick Test Script

Create a file `test_liboqs.py`:

```python
import os
print(f"LIBOQS_DIR: {os.environ.get('LIBOQS_DIR', 'NOT SET')}")

try:
    import oqs
    print("✓ liboqs-python imported successfully")
    
    with oqs.KeyEncapsulation("Kyber512") as kem:
        pub = kem.generate_keypair()
        print(f"✓ Kyber512 keypair generated: {len(pub)} bytes")
        print("SUCCESS: liboqs is working!")
except Exception as e:
    print(f"✗ Error: {e}")
```

Run it:
```powershell
python test_liboqs.py
```

