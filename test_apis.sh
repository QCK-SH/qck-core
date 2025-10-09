#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:10180/api/v1"
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser${TIMESTAMP}@example.com"
TEST_PASSWORD="TestPass123!"

echo "========================================="
echo "QCK Core API Testing Suite"
echo "Base URL: $BASE_URL"
echo "========================================="
echo ""

# 1. Health Check
echo -e "${YELLOW}1. Testing Health Check${NC}"
HEALTH=$(curl -s "$BASE_URL/health")
if echo "$HEALTH" | jq -e '.status == "healthy"' > /dev/null; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo "$HEALTH" | jq -c '{status, components: .components | keys}'
else
    echo -e "${RED}✗ Health check failed${NC}"
fi
echo ""

# 2. Register User
echo -e "${YELLOW}2. Testing User Registration${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"password_confirmation\":\"$TEST_PASSWORD\",\"full_name\":\"Test User $TIMESTAMP\",\"accept_terms\":true}")

if echo "$REGISTER_RESPONSE" | jq -e '.success == true' > /dev/null; then
    echo -e "${GREEN}✓ Registration successful${NC}"
    USER_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.data.user_id')
    echo "  User ID: $USER_ID"
    echo "  Email: $TEST_EMAIL"
else
    echo -e "${RED}✗ Registration failed${NC}"
    echo "$REGISTER_RESPONSE" | jq
fi
echo ""

# 3. Login
echo -e "${YELLOW}3. Testing Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

if echo "$LOGIN_RESPONSE" | jq -e '.success == true' > /dev/null; then
    echo -e "${GREEN}✓ Login successful${NC}"
    ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.access_token')
    REFRESH_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.refresh_token')
    echo "  Got access token (${#ACCESS_TOKEN} chars)"
    echo "  Got refresh token (${#REFRESH_TOKEN} chars)"
else
    echo -e "${RED}✗ Login failed${NC}"
    echo "$LOGIN_RESPONSE" | jq
    exit 1
fi
echo ""

# 4. Get Current User
echo -e "${YELLOW}4. Testing Get Current User (/auth/me)${NC}"
ME_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/me" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$ME_RESPONSE" | jq -e '.success == true' > /dev/null; then
    echo -e "${GREEN}✓ Get current user successful${NC}"
    echo "$ME_RESPONSE" | jq -c '.data | {email, subscription_tier}'
else
    echo -e "${RED}✗ Get current user failed${NC}"
    echo "$ME_RESPONSE" | jq
fi
echo ""

# 5. Validate Token
echo -e "${YELLOW}5. Testing Token Validation${NC}"
VALIDATE_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/validate" \
    -H "Content-Type: application/json" \
    -d "{\"token\":\"$ACCESS_TOKEN\"}")

if echo "$VALIDATE_RESPONSE" | jq -e '.valid == true' > /dev/null; then
    echo -e "${GREEN}✓ Token validation successful${NC}"
else
    echo -e "${RED}✗ Token validation failed${NC}"
    echo "$VALIDATE_RESPONSE" | jq
fi
echo ""

# 6. Create Link
echo -e "${YELLOW}6. Testing Link Creation${NC}"
LINK_RESPONSE=$(curl -s -X POST "$BASE_URL/links" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"url\":\"https://www.example.com/test-$TIMESTAMP\"}")

if echo "$LINK_RESPONSE" | jq -e '.short_code' > /dev/null; then
    echo -e "${GREEN}✓ Link creation successful${NC}"
    SHORT_CODE=$(echo "$LINK_RESPONSE" | jq -r '.short_code')
    LINK_ID=$(echo "$LINK_RESPONSE" | jq -r '.id')
    echo "  Short code: $SHORT_CODE"
    echo "  Link ID: $LINK_ID"
    echo "  Short URL: http://localhost:10180/$SHORT_CODE"
else
    echo -e "${RED}✗ Link creation failed${NC}"
    echo "$LINK_RESPONSE" | jq
fi
echo ""

# 7. List Links
echo -e "${YELLOW}7. Testing List Links${NC}"
LIST_RESPONSE=$(curl -s -X GET "$BASE_URL/links" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$LIST_RESPONSE" | jq -e '.data' > /dev/null; then
    LINK_COUNT=$(echo "$LIST_RESPONSE" | jq '.data | length')
    echo -e "${GREEN}✓ List links successful${NC}"
    echo "  Total links: $LINK_COUNT"
else
    echo -e "${RED}✗ List links failed${NC}"
    echo "$LIST_RESPONSE" | jq
fi
echo ""

# 8. Get Link Details
if [ ! -z "$LINK_ID" ]; then
    echo -e "${YELLOW}8. Testing Get Link Details${NC}"
    LINK_DETAIL=$(curl -s -X GET "$BASE_URL/links/$LINK_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    if echo "$LINK_DETAIL" | jq -e '.short_code' > /dev/null; then
        echo -e "${GREEN}✓ Get link details successful${NC}"
        echo "$LINK_DETAIL" | jq -c '{short_code, original_url, total_clicks}'
    else
        echo -e "${RED}✗ Get link details failed${NC}"
        echo "$LINK_DETAIL" | jq
    fi
    echo ""
fi

# 9. Test URL Redirection
if [ ! -z "$SHORT_CODE" ]; then
    echo -e "${YELLOW}9. Testing URL Redirection${NC}"
    REDIRECT_RESPONSE=$(curl -s -I "http://localhost:10180/$SHORT_CODE" | head -n 2)

    if echo "$REDIRECT_RESPONSE" | grep -q "308 Permanent Redirect"; then
        echo -e "${GREEN}✓ URL redirection working${NC}"
        echo "  Returns 308 Permanent Redirect"
    else
        echo -e "${RED}✗ URL redirection failed${NC}"
        echo "$REDIRECT_RESPONSE"
    fi
    echo ""

    # 10. Test Preview
    echo -e "${YELLOW}10. Testing URL Preview${NC}"
    PREVIEW_RESPONSE=$(curl -s "http://localhost:10180/$SHORT_CODE/preview")

    if echo "$PREVIEW_RESPONSE" | jq -e '.destination_url' > /dev/null; then
        echo -e "${GREEN}✓ URL preview working${NC}"
        echo "$PREVIEW_RESPONSE" | jq -c '{destination_url, is_safe}'
    else
        echo -e "${RED}✗ URL preview failed${NC}"
        echo "$PREVIEW_RESPONSE"
    fi
    echo ""
fi

# 11. Update Link
if [ ! -z "$LINK_ID" ]; then
    echo -e "${YELLOW}11. Testing Update Link${NC}"
    UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_URL/links/$LINK_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"url\":\"https://www.updated-example.com/test-$TIMESTAMP\"}")

    if echo "$UPDATE_RESPONSE" | jq -e '.short_code' > /dev/null; then
        echo -e "${GREEN}✓ Link update successful${NC}"
        echo "$UPDATE_RESPONSE" | jq -c '{short_code, original_url}'
    else
        echo -e "${RED}✗ Link update failed${NC}"
        echo "$UPDATE_RESPONSE" | jq
    fi
    echo ""
fi

# 12. Get Link Stats
if [ ! -z "$LINK_ID" ]; then
    echo -e "${YELLOW}12. Testing Get Link Stats${NC}"
    STATS_RESPONSE=$(curl -s -X GET "$BASE_URL/links/$LINK_ID/stats" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    if echo "$STATS_RESPONSE" | jq -e '.' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Get link stats successful${NC}"
        echo "$STATS_RESPONSE" | jq -c
    else
        echo -e "${YELLOW}⚠ Link stats endpoint may not be implemented${NC}"
    fi
    echo ""
fi

# 13. Refresh Token
echo -e "${YELLOW}13. Testing Refresh Token${NC}"
REFRESH_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/refresh" \
    -H "Content-Type: application/json" \
    -d "{\"refresh_token\":\"$REFRESH_TOKEN\"}")

if echo "$REFRESH_RESPONSE" | jq -e '.data.access_token' > /dev/null; then
    echo -e "${GREEN}✓ Token refresh successful${NC}"
    NEW_ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | jq -r '.data.access_token')
    echo "  Got new access token (${#NEW_ACCESS_TOKEN} chars)"
else
    echo -e "${RED}✗ Token refresh failed${NC}"
    echo "$REFRESH_RESPONSE" | jq
fi
echo ""

# 14. Logout
echo -e "${YELLOW}14. Testing Logout${NC}"
LOGOUT_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/logout" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$LOGOUT_RESPONSE" | jq -e '.success == true' > /dev/null; then
    echo -e "${GREEN}✓ Logout successful${NC}"
else
    echo -e "${RED}✗ Logout failed${NC}"
    echo "$LOGOUT_RESPONSE" | jq
fi
echo ""

# 15. Delete Link
if [ ! -z "$LINK_ID" ]; then
    echo -e "${YELLOW}15. Testing Delete Link${NC}"
    DELETE_RESPONSE=$(curl -s -X DELETE "$BASE_URL/links/$LINK_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    if [ -z "$DELETE_RESPONSE" ] || echo "$DELETE_RESPONSE" | jq -e '.success == true' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Link deletion successful${NC}"
    else
        echo -e "${RED}✗ Link deletion failed${NC}"
        echo "$DELETE_RESPONSE" | jq
    fi
    echo ""
fi

# Summary
echo "========================================="
echo -e "${YELLOW}Test Summary${NC}"
echo "========================================="
echo "All core API endpoints have been tested."
echo "Check the results above for any failures."
echo ""