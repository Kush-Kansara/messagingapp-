# Testing Guide - Post-Quantum Document Server

Now that your backend is running, here's how to test it!

## Quick Test (Using Browser/Postman)

### 1. Check Server Status

Open in browser: `http://localhost:8000` (or `https://localhost:8443` if using HTTPS)

Should see:
```json
{
  "message": "Post-Quantum Secure Document Server API",
  "status": "running"
}
```

### 2. View API Documentation

Open: `http://localhost:8000/docs`

This shows all available endpoints with interactive testing.

### 3. Test Authentication

#### Register a User

```bash
POST http://localhost:8000/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "password": "Test123!@#",
  "area_code": "+1",
  "phone_number": "1234567890"
}
```

#### Login

```bash
POST http://localhost:8000/auth/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "Test123!@#"
}
```

**Save the cookie** - it contains your JWT token!

### 4. Test Post-Quantum Handshake

#### Get Server's Public Key

```bash
GET http://localhost:8000/pq/kem-public-key
```

#### Perform Handshake (requires authentication)

```bash
POST http://localhost:8000/pq/handshake
Cookie: access_token=YOUR_JWT_TOKEN
Content-Type: application/json

{
  "ciphertext": "base64_encoded_ciphertext_here"
}
```

*Note: The frontend handles this automatically after login*

### 5. Test Document Endpoints

#### Upload a Document (Plaintext)

```bash
POST http://localhost:8000/documents
Cookie: access_token=YOUR_JWT_TOKEN
Content-Type: application/json

{
  "title": "My First HTML Page",
  "content": "<!DOCTYPE html><html><head><title>Test</title></head><body><h1>Hello World!</h1></body></html>"
}
```

#### List All Documents

```bash
GET http://localhost:8000/documents
Cookie: access_token=YOUR_JWT_TOKEN
```

#### Get Specific Document

```bash
GET http://localhost:8000/documents/{document_id}
Cookie: access_token=YOUR_JWT_TOKEN
```

#### Update Document

```bash
PUT http://localhost:8000/documents/{document_id}
Cookie: access_token=YOUR_JWT_TOKEN
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "<html><body><h1>Updated Content</h1></body></html>"
}
```

#### Delete Document

```bash
DELETE http://localhost:8000/documents/{document_id}
Cookie: access_token=YOUR_JWT_TOKEN
```

## Using Python/curl

### Register User

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Test123!@#","area_code":"+1","phone_number":"1234567890"}'
```

### Login and Save Cookie

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Test123!@#"}' \
  -c cookies.txt
```

### Upload Document

```bash
curl -X POST http://localhost:8000/documents \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{"title":"My Page","content":"<html><body><h1>Hello</h1></body></html>"}'
```

### List Documents

```bash
curl http://localhost:8000/documents -b cookies.txt
```

## Using Python Script

Create `test_api.py`:

```python
import requests

BASE_URL = "http://localhost:8000"

# Register
response = requests.post(f"{BASE_URL}/auth/register", json={
    "username": "testuser",
    "password": "Test123!@#",
    "area_code": "+1",
    "phone_number": "1234567890"
})
print("Register:", response.json())

# Login
response = requests.post(f"{BASE_URL}/auth/login", json={
    "username": "testuser",
    "password": "Test123!@#"
}, cookies=response.cookies)
print("Login:", response.json())

# Get session
session = requests.Session()
session.cookies = response.cookies

# Upload document
response = session.post(f"{BASE_URL}/documents", json={
    "title": "Test HTML Page",
    "content": "<!DOCTYPE html><html><head><title>Test</title></head><body><h1>Hello World!</h1></body></html>"
})
print("Upload:", response.json())
doc_id = response.json()["id"]

# List documents
response = session.get(f"{BASE_URL}/documents")
print("List:", response.json())

# Get document
response = session.get(f"{BASE_URL}/documents/{doc_id}")
print("Get:", response.json())
```

Run: `python test_api.py`

## Next Steps

1. ✅ Test backend API endpoints
2. ⏳ Update frontend to work with documents
3. ⏳ Test full application flow
4. ⏳ Verify post-quantum security

Let's update the frontend next!

