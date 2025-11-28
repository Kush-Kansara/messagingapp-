# Building liboqs from Source on Windows

## Your Situation
- Location: `C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0`
- Status: Source code (needs to be built)
- No build folder yet (we'll create it)

## Prerequisites

You need these installed:
1. **CMake** - Download from https://cmake.org/download/
   - Choose "Windows x64 Installer"
   - During installation, check "Add CMake to system PATH"

2. **Visual Studio Build Tools** (or Visual Studio)
   - Download: https://visualstudio.microsoft.com/downloads/
   - Choose "Build Tools for Visual Studio 2022"
   - During installation, select "Desktop development with C++"

## Build Steps

### Step 1: Open Developer Command Prompt

**Option A: Use Visual Studio Developer PowerShell**
- Search for "Developer PowerShell for VS 2022" in Start menu
- Open it

**Option B: Use regular PowerShell with Visual Studio**
- Open PowerShell
- Run: `& "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\Launch-VsDevShell.ps1"`

### Step 2: Navigate to liboqs

```powershell
cd C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0
```

### Step 3: Create Build Directory

```powershell
mkdir build
cd build
```

### Step 4: Configure with CMake

```powershell
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
```

**If that doesn't work, try:**
```powershell
cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=Release
```

### Step 5: Build

```powershell
cmake --build . --config Release
```

This will take several minutes (5-15 minutes depending on your computer).

### Step 6: Set Environment Variable

After building, set the environment variable:

```powershell
$env:LIBOQS_DIR = "C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0\build"
```

Or set it permanently (see below).

## Alternative: Easier Method (If Building Fails)

If building is too complex, you can:

1. **Use the fallback for your project** - Document that the code uses liboqs-python
2. **Try a different approach** - Use Docker or WSL
3. **Skip for demo** - Show the architecture, explain liboqs would be installed in production

## After Building

Once built, the DLLs will be in:
```
C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0\build\bin\Release\
```

Set `LIBOQS_DIR` to:
```
C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0\build
```

Then test:
```powershell
cd PostQuantumMessagingApp\backend
.\venv\Scripts\Activate.ps1
python verify_pq.py
```

