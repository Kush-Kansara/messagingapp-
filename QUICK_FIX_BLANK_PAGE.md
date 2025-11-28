# Quick Fix for Blank Page

## Immediate Steps

### 1. Open Browser Console (F12)

**This is the most important step!** The console will show you exactly what's wrong.

Look for:
- ❌ Red error messages
- ⚠️ Yellow warnings
- Any messages about failed requests

### 2. Check if Frontend is Running

```powershell
# Make sure you're in the project root
cd frontend
npm run dev
```

You should see:
```
VITE v5.x.x  ready in xxx ms
➜  Local:   http://localhost:5173/
```

### 3. Check if Backend is Running

```powershell
cd backend
# Should see uvicorn running
# Or start it:
.\start_server.ps1
```

### 4. Common Issues & Fixes

#### Issue: "Cannot GET /" or 404
**Fix:** Make sure you're on http://localhost:5173 (not 8000)

#### Issue: "Failed to fetch" or Network Error
**Fix:** 
- Backend not running → Start it
- Wrong API URL → Check `frontend/.env` or use default `http://localhost:8000`

#### Issue: Blank page with no errors
**Fix:**
- Hard refresh: `Ctrl+F5`
- Clear cache: `Ctrl+Shift+Delete`
- Check if React is loading (should see "Loading..." briefly)

#### Issue: Redirect loop
**Fix:**
- Clear cookies for localhost
- Check browser DevTools → Application → Cookies

### 5. What Should Happen

1. **Not logged in** → Should see Login page at `/login`
2. **Logged in** → Should see Chat interface at `/chat`
3. **Root URL** → Should redirect to `/chat` (or `/login` if not authenticated)

### 6. Debug Checklist

- [ ] Frontend running on port 5173?
- [ ] Backend running on port 8000?
- [ ] Browser console shows no errors?
- [ ] Network tab shows successful requests?
- [ ] URL is http://localhost:5173?

### 7. Still Blank?

**Share these details:**
1. Browser console errors (F12 → Console tab)
2. Network tab errors (F12 → Network tab)
3. What URL you're on
4. Whether you see "Loading..." or completely blank

## Most Likely Causes

1. **Backend not running** → Start it with `.\start_server.ps1`
2. **JavaScript error** → Check browser console (F12)
3. **CORS error** → Backend CORS not configured correctly
4. **Authentication redirect** → Should redirect to `/login` if not logged in

