# Troubleshooting Blank Page

If you see a blank page after refreshing, follow these steps:

## Step 1: Check Browser Console

**Open Browser DevTools (F12)** and check:

1. **Console Tab** - Look for JavaScript errors (red text)
2. **Network Tab** - Check if requests are failing
3. **Any error messages** - Copy and share them

## Step 2: Check if Frontend is Running

```powershell
# In frontend directory
cd frontend
npm run dev
```

You should see:
```
VITE v5.x.x  ready in xxx ms
➜  Local:   http://localhost:5173/
```

## Step 3: Check if Backend is Running

```powershell
# In backend directory
cd backend
# Should see uvicorn running
```

Or test in browser: http://localhost:8000

## Step 4: Common Issues

### Issue: "Cannot GET /" or 404

**Solution:**
- Make sure you're going to http://localhost:5173 (not 8000)
- Frontend runs on 5173, backend on 8000

### Issue: Blank white/black page

**Possible causes:**
1. **JavaScript error** - Check browser console (F12)
2. **Not authenticated** - Should redirect to /login
3. **React error** - Check console for React errors

### Issue: "Failed to fetch" or CORS errors

**Solution:**
- Make sure backend is running on port 8000
- Check backend CORS settings in `backend/app/main.py`
- Verify `VITE_API_URL` in frontend `.env` (if exists)

### Issue: Redirect loop

**Solution:**
- Clear browser cookies/localStorage
- Check authentication state in browser DevTools → Application → Local Storage

## Step 5: Quick Fixes

### Clear Browser Cache

1. Press `Ctrl+Shift+Delete`
2. Clear cache and cookies
3. Refresh page

### Hard Refresh

- Windows: `Ctrl+F5` or `Ctrl+Shift+R`
- This forces reload of all assets

### Check URL

Make sure you're on:
- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8000

## Step 6: Verify Setup

### Frontend Running?

```powershell
cd frontend
npm run dev
```

### Backend Running?

```powershell
cd backend
.\start_server.ps1
```

### Check Browser Console

Open DevTools (F12) and look for:
- ✅ No red errors
- ✅ Network requests succeeding
- ✅ React app loading

## Step 7: Debug Steps

1. **Open browser console** (F12)
2. **Check for errors** - Any red text?
3. **Check Network tab** - Are requests failing?
4. **Check React DevTools** (if installed) - Is React rendering?

## Still Blank?

Share:
1. **Browser console errors** (F12 → Console)
2. **Network tab errors** (F12 → Network)
3. **What URL you're on**
4. **Whether frontend/backend are running**

