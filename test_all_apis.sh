#!/bin/bash

# QCK Backend API Test Script
# Tests all endpoints in the OSS backend via nginx router

set -e

BASE_URL="http://localhost:10180"
API_BASE_URL="http://localhost:10180/api"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Helper function to test API endpoint
test_endpoint() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local auth="$5"
    local expected_status="$6"

    echo -e "\n${YELLOW}Testing: ${name}${NC}"
    echo "  ${method} ${API_BASE_URL}${endpoint}"

    # Build curl command
    local cmd="curl -s -w '\nHTTP_CODE:%{http_code}\n' -X $method"

    if [ -n "$data" ]; then
        cmd="$cmd -H 'Content-Type: application/json' -d '$data'"
    fi

    if [ -n "$auth" ]; then
        cmd="$cmd -H 'Authorization: Bearer $auth'"
    fi

    cmd="$cmd ${API_BASE_URL}${endpoint}"

    # Execute curl
    local response=$(eval $cmd 2>&1)
    local http_code=$(echo "$response" | grep "HTTP_CODE:" | tail -1 | cut -d':' -f2)

    # Check HTTP status
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "  ${GREEN}✓ PASSED${NC} (HTTP $http_code)"
        ((PASSED++))
    else
        echo -e "  ${RED}✗ FAILED${NC}"
        echo "  Expected: HTTP $expected_status"
        echo "  Got: HTTP $http_code"
        echo "  Response:" && echo "$response" | grep -v "HTTP_CODE:" | head -10
        ((FAILED++))
    fi

    # Return the response for parsing
    echo "$response"
}

echo "====================================="
echo "QCK Backend API Test Suite"
echo "====================================="

# 1. System Endpoints
echo -e "\n${YELLOW}=== SYSTEM ENDPOINTS ===${NC}"

test_endpoint "Health Check" "GET" "/v1/health" "" "" "200" > /dev/null
test_endpoint "Rate Limit Metrics" "GET" "/v1/metrics/rate-limiting" "" "" "200" > /dev/null

# 2. Auth Endpoints (Public)
echo -e "\n${YELLOW}=== AUTHENTICATION ENDPOINTS ===${NC}"

# Generate unique email for testing
TEST_EMAIL="testuser$(date +%s)@example.com"
TEST_PASSWORD="Test123!@#"

# Register new user
REGISTER_DATA="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"password_confirmation\":\"$TEST_PASSWORD\",\"full_name\":\"Test User\",\"accept_terms\":true}"
test_endpoint "Register User" "POST" "/v1/auth/register" "$REGISTER_DATA" "" "201" > /dev/null

# Login
LOGIN_DATA="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"remember_me\":false}"
echo -e "\n${YELLOW}Attempting login...${NC}"
LOGIN_RESPONSE=$(test_endpoint "Login" "POST" "/v1/auth/login" "$LOGIN_DATA" "" "200")

# Extract access token (simple parsing)
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4 | head -1)

if [ -n "$ACCESS_TOKEN" ]; then
    echo -e "${GREEN}✓ Got access token${NC}"

    # 3. Protected Endpoints (with JWT)
    echo -e "\n${YELLOW}=== PROTECTED ENDPOINTS ===${NC}"

    # Get current user
    test_endpoint "Get Current User (/auth/me)" "GET" "/v1/auth/me" "" "$ACCESS_TOKEN" "200" > /dev/null

    # Validate token
    VALIDATE_DATA="{\"token\":\"$ACCESS_TOKEN\"}"
    test_endpoint "Validate Token" "POST" "/v1/auth/validate" "$VALIDATE_DATA" "$ACCESS_TOKEN" "200" > /dev/null

    # 4. Link Management
    echo -e "\n${YELLOW}=== LINK MANAGEMENT ===${NC}"

    # Create link
    LINK_DATA="{\"url\":\"https://example.com\",\"title\":\"Test Link\"}"
    echo -e "\n${YELLOW}Creating link...${NC}"
    CREATE_LINK_RESPONSE=$(test_endpoint "Create Link" "POST" "/v1/links" "$LINK_DATA" "$ACCESS_TOKEN" "201")

    # Extract link ID
    LINK_ID=$(echo "$CREATE_LINK_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | head -1)

    if [ -n "$LINK_ID" ]; then
        echo -e "${GREEN}✓ Link created with ID: $LINK_ID${NC}"

        # Get link
        test_endpoint "Get Link by ID" "GET" "/v1/links/$LINK_ID" "" "$ACCESS_TOKEN" "200" > /dev/null

        # List links
        test_endpoint "List Links" "GET" "/v1/links" "" "$ACCESS_TOKEN" "200" > /dev/null

        # Get link stats
        test_endpoint "Get Link Stats" "GET" "/v1/links/$LINK_ID/stats" "" "$ACCESS_TOKEN" "200" > /dev/null

        # Update link
        UPDATE_DATA="{\"title\":\"Updated Title\"}"
        test_endpoint "Update Link" "PUT" "/v1/links/$LINK_ID" "$UPDATE_DATA" "$ACCESS_TOKEN" "200" > /dev/null

        # Delete link
        test_endpoint "Delete Link" "DELETE" "/v1/links/$LINK_ID" "" "$ACCESS_TOKEN" "204" > /dev/null
    else
        echo -e "${RED}✗ Failed to create link${NC}"
        ((FAILED++))
    fi

    # Check alias availability
    test_endpoint "Check Alias Availability" "GET" "/v1/links/check-alias/myalias" "" "$ACCESS_TOKEN" "200" > /dev/null

    # Logout
    test_endpoint "Logout" "POST" "/v1/auth/logout" "" "$ACCESS_TOKEN" "200" > /dev/null

else
    echo -e "${RED}✗ Login failed, cannot test protected endpoints${NC}"
    ((FAILED++))
fi

# Summary
echo -e "\n====================================="
echo -e "Test Summary"
echo -e "====================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "Total: $((PASSED + FAILED))"
echo -e "====================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
