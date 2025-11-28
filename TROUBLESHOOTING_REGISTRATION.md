# Troubleshooting Registration Issues

If you're getting "Registration failed. Please try again.", here's how to debug:

## Step 1: Check Backend Logs

Look at your backend terminal for error messages. Common errors:

### "Database not initialized"
- **Fix**: Make sure MongoDB is running
- **Check**: `Get-Service MongoDB` (Windows) or `mongosh` connection

### "Username already registered"
- **Fix**: Try a different username
- **Check**: The username must be unique

### "This phone number is already registered"
- **Fix**: Use a different phone number
- **Check**: Phone number must be unique

### Password Validation Errors
Password must have:
- ✅ At least 8 characters
- ✅ At least one uppercase letter (A-Z)
- ✅ At least one lowercase letter (a-z)
- ✅ At least one digit (0-9)
- ✅ At least one special character (!@#$%^&*(), etc.)

**Example valid password**: `Test123!@#`

### Username Validation Errors
Username must:
- ✅ Be 3-50 characters
- ✅ Only contain letters, numbers, and underscores
- ✅ No spaces or special characters

**Example valid username**: `testuser123` or `test_user`

### Area Code Validation
Area code must:
- ✅ Start with `+`
- ✅ Followed by 1-4 digits
- ✅ Examples: `+1`, `+44`, `+91`, `+1234`

### Phone Number Validation
Phone number must:
- ✅ Be 7-15 digits
- ✅ Only numbers (no dashes, spaces, or parentheses)

**Example valid phone**: `1234567890`

## Step 2: Check Browser Console

Open browser DevTools (F12) and check the Console tab for:
- Network errors
- CORS errors
- Detailed error messages

The updated error handling will now show the actual backend error message.

## Step 3: Test Backend Directly

### Test with curl:

```powershell
curl -X POST http://localhost:8000/auth/register `
  -H "Content-Type: application/json" `
  -d '{"username":"testuser","password":"Test123!@#","area_code":"+1","phone_number":"1234567890"}'
```

### Test with Python:

```python
import requests

response = requests.post("http://localhost:8000/auth/register", json={
    "username": "testuser",
    "password": "Test123!@#",
    "area_code": "+1",
    "phone_number": "1234567890"
})

print(response.status_code)
print(response.json())
```

## Step 4: Common Issues

### Issue: "Cannot connect to server"
**Solution:**
- Make sure backend is running: `http://localhost:8000`
- Check backend terminal for errors
- Verify port 8000 is not blocked

### Issue: CORS Error
**Solution:**
- Backend CORS is configured for `http://localhost:5173`
- Make sure frontend is running on that port
- Check `backend/app/main.py` has your frontend URL in `origins` list

### Issue: MongoDB Connection Error
**Solution:**
- Start MongoDB: `Start-Service MongoDB` (Windows)
- Check `.env` file has correct `MONGO_URL`
- Test connection: `mongosh` or `mongo`

### Issue: Password Requirements Not Met
**Solution:**
- Use a password like: `Test123!@#`
- Must have: uppercase, lowercase, digit, special character
- Minimum 8 characters

## Step 5: Check Registration Form

Make sure you're filling out:
- ✅ Username (3-50 chars, alphanumeric + underscore)
- ✅ Password (8+ chars, with uppercase, lowercase, digit, special)
- ✅ Confirm Password (must match)
- ✅ Area Code (e.g., +1)
- ✅ Phone Number (7-15 digits, numbers only)

## Quick Test

Try registering with these exact values:

- **Username**: `testuser123`
- **Password**: `Test123!@#`
- **Area Code**: `+1`
- **Phone Number**: `1234567890`

If this works, the issue is with your input format.

## Still Having Issues?

1. **Check backend logs** - Look for the actual error message
2. **Check browser console** - Look for network errors
3. **Test API directly** - Use curl or Postman to test `/auth/register`
4. **Verify MongoDB** - Make sure database is connected
5. **Check .env file** - Verify `MONGO_URL` and `JWT_SECRET` are set

## Debug Mode

To see more details, check:
- Browser DevTools → Network tab → Look at the failed request
- Backend terminal → Look for error stack traces
- Browser Console → Look for JavaScript errors

The updated error handling will now show you the exact error from the backend!

