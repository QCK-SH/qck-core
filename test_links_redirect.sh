#!/bin/bash

API_BASE="http://localhost:10180/api"

echo "=== 1. Register User ==="
REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/v1/auth/register" \
  -H 'Content-Type: application/json' \
  -d '{"email":"linktest@example.com","password":"TestPass123*","password_confirmation":"TestPass123*","full_name":"Link Test","accept_terms":true}')
echo "$REGISTER_RESPONSE" | python3 -m json.tool | head -10

echo -e "\n=== 2. Login ==="
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"linktest@example.com","password":"TestPass123*","remember_me":false}')

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
echo "Access Token: ${ACCESS_TOKEN:0:50}..."

echo -e "\n=== 3. Create Link via POST /api/v1/links ==="
CREATE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST "$API_BASE/v1/links" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{"url":"https://example.com","title":"Test Link for Redirect"}')

HTTP_CODE=$(echo "$CREATE_RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
LINK_DATA=$(echo "$CREATE_RESPONSE" | grep -v "HTTP_CODE:")

echo "$LINK_DATA" | python3 -m json.tool

if [ "$HTTP_CODE" = "201" ]; then
    echo -e "\n✓ Link created successfully (HTTP $HTTP_CODE)"

    # Extract short_code
    SHORT_CODE=$(echo "$LINK_DATA" | grep -o '"short_code":"[^"]*"' | cut -d'"' -f4)
    SHORT_URL=$(echo "$LINK_DATA" | grep -o '"short_url":"[^"]*"' | cut -d'"' -f4)

    echo -e "\nShort Code: $SHORT_CODE"
    echo "Short URL: $SHORT_URL"

    echo -e "\n=== 4. Test Redirect via /{shortcode} ==="
    echo "Testing: http://localhost:10180/$SHORT_CODE"

    REDIRECT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nREDIRECT_URL:%{redirect_url}\n" \
      -L --max-redirs 0 \
      "http://localhost:10180/$SHORT_CODE" 2>&1)

    REDIRECT_CODE=$(echo "$REDIRECT_RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
    REDIRECT_LOCATION=$(echo "$REDIRECT_RESPONSE" | grep "REDIRECT_URL:" | cut -d':' -f2-)

    echo "HTTP Code: $REDIRECT_CODE"
    echo "Redirect Location: $REDIRECT_LOCATION"

    if [ "$REDIRECT_CODE" = "301" ] || [ "$REDIRECT_CODE" = "302" ] || [ "$REDIRECT_CODE" = "307" ] || [ "$REDIRECT_CODE" = "308" ]; then
        echo -e "\n✓ Redirect working (HTTP $REDIRECT_CODE)"
    else
        echo -e "\n✗ Redirect failed (HTTP $REDIRECT_CODE)"
        echo "$REDIRECT_RESPONSE" | head -20
    fi

    echo -e "\n=== 5. Test Logout via POST /api/v1/auth/logout ==="
    LOGOUT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST "$API_BASE/v1/auth/logout" \
      -H "Authorization: Bearer $ACCESS_TOKEN")

    LOGOUT_CODE=$(echo "$LOGOUT_RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
    LOGOUT_DATA=$(echo "$LOGOUT_RESPONSE" | grep -v "HTTP_CODE:")

    echo "HTTP Code: $LOGOUT_CODE"
    echo "$LOGOUT_DATA" | python3 -m json.tool 2>/dev/null || echo "$LOGOUT_DATA"

    if [ "$LOGOUT_CODE" = "200" ]; then
        echo -e "\n✓ Logout successful (HTTP $LOGOUT_CODE)"
    else
        echo -e "\n✗ Logout failed (HTTP $LOGOUT_CODE)"
    fi

else
    echo -e "\n✗ Link creation failed (HTTP $HTTP_CODE)"
    echo "$LINK_DATA"
fi

echo -e "\n=== Summary ==="
echo "Link Creation: $([ "$HTTP_CODE" = "201" ] && echo "✓ PASS" || echo "✗ FAIL")"
echo "Redirect: $([ "$REDIRECT_CODE" = "301" ] || [ "$REDIRECT_CODE" = "302" ] || [ "$REDIRECT_CODE" = "307" ] || [ "$REDIRECT_CODE" = "308" ] && echo "✓ PASS" || echo "✗ FAIL")"
echo "Logout: $([ "$LOGOUT_CODE" = "200" ] && echo "✓ PASS" || echo "✗ FAIL")"
