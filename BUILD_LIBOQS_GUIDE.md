# Building liboqs from Source on Windows

## Your Situation

You have liboqs source code at:
```
C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0
```

You need to **build it** before you can use it.

## Prerequisites

You need these installed:

1. **CMake** (Required)
   - Download: https://cmake.org/download/
   - Install and make sure it's in your PATH
   - Verify: `cmake --version`

2. **Visual Studio Build Tools** (Required)
   - Download: https://visualstudio.microsoft.com/downloads/
   - Install "Desktop development with C++" workload
   - OR install "Build Tools for Visual Studio"

## Option 1: Use the Build Script (Easiest)

I've created a build script for you:

```powershell
cd PostQuantumMessagingApp\backend
powershell -ExecutionPolicy Bypass -File build_liboqs.ps1
```

This will:
- Check for CMake and Visual Studio
- Configure and build liboqs
- Set the environment variable
- Take about 10-30 minutes

## Option 2: Build Manually

### Step 1: Open PowerShell in liboqs directory

```powershell
cd C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0
```

### Step 2: Create build directory

```powershell
mkdir build
cd build
```

### Step 3: Configure with CMake

```powershell
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
```

If that doesn't work, try:
```powershell
cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=Release
```

Or if you have MinGW:
```powershell
cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
```

### Step 4: Build

```powershell
cmake --build . --config Release
```

This will take 10-30 minutes.

### Step 5: Set Environment Variable

After building, set:
```powershell
$env:LIBOQS_DIR = "C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0\build"
```

Or set it permanently (see below).

## Option 3: Use Pre-built Binaries (Easier, if available)

Instead of building, you could:

1. Check the GitHub releases page for Windows binaries:
   https://github.com/open-quantum-safe/liboqs/releases

2. Look for files like:
   - `liboqs-windows-x64.zip`
   - Or similar pre-built packages

3. Extract those instead (no building needed!)

## Setting Environment Variable Permanently

After building, set it permanently:

1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Click "Environment Variables"
3. Under "User variables", click "New"
4. Name: `LIBOQS_DIR`
5. Value: `C:\Users\xxcbj\Desktop\liboqs-0.15.0\liboqs-0.15.0\build`
6. Click OK
7. **Restart your terminal**

## Verify It Works

After building and setting the variable:

```powershell
cd PostQuantumMessagingApp\backend
.\venv\Scripts\Activate.ps1
python verify_pq.py
```

## Troubleshooting

### "CMake not found"
- Install CMake from https://cmake.org/download/
- Make sure it's in your PATH
- Restart terminal

### "Visual Studio not found"
- Install Visual Studio Build Tools
- Or install Visual Studio Community with C++ workload

### Build fails
- Make sure you have enough disk space (needs ~500MB)
- Check the error message
- Try a different CMake generator

### "No oqs shared libraries found"
- Make sure `LIBOQS_DIR` points to the `build` directory (not the source)
- Check that `build\bin\Release\oqs.dll` exists
- Restart terminal after setting environment variable

## Quick Check: Do You Have the Tools?

Run these to check:

```powershell
cmake --version        # Should show version
where cl              # Should find Visual Studio compiler
```

If both work, you're ready to build!

