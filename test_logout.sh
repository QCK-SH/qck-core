#!/bin/bash

# Test logout endpoint specifically

API_BASE="http://localhost:10180/api"

# Register user
echo "=== Registering user ==="
REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/v1/auth/register" \
  -H 'Content-Type: application/json' \
  -d '{"email":"logout-test@example.com","password":"TestPass123*","password_confirmation":"TestPass123*","full_name":"Logout Test","accept_terms":true}')

echo "$REGISTER_RESPONSE" | python3 -m json.tool

# Login
echo -e "\n=== Logging in ==="
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"logout-test@example.com","password":"TestPass123*","remember_me":false}')

echo "$LOGIN_RESPONSE" | python3 -m json.tool

# Extract token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

echo -e "\n=== Access Token ==="
echo "$ACCESS_TOKEN"

# Test logout
echo -e "\n=== Testing logout ==="
LOGOUT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST "$API_BASE/v1/auth/logout" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "$LOGOUT_RESPONSE"
echo -e "\n=== Logout response parsed ==="
echo "$LOGOUT_RESPONSE" | grep -v "HTTP_CODE:" | python3 -m json.tool 2>&1 || echo "No JSON response"

# Check backend logs
echo -e "\n=== Backend logs (last 20 lines) ==="
docker logs --tail=20 qck-backend-oss-dev 2>&1 | grep -i "logout\|error" || echo "No logout/error logs"
