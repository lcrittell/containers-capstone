#!/bin/bash

set -uo pipefail

POD_NAME="containers-capstone-pod"
DB_CONTAINER="containers-capstone-pod-capstone-db"
WEB_CONTAINER="containers-capstone-pod-capstone-web"

BASE_URL="${BASE_URL:-http://localhost:5003}"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "[PASS] $1"
    ((PASS_COUNT+=1))
}

fail() {
    echo "[FAIL] $1"
    ((FAIL_COUNT+=1))
}

echo "=================================="
echo " Podman Deployment Validation"
echo "=================================="
echo ""

# Check Podman pod
if podman pod inspect "$POD_NAME" >/dev/null 2>&1; then
    pass "Podman pod exists"
else
    fail "Podman pod does not exist"
fi

# Check individual containers
check_container() {
    local container="$1"
    local status

    if ! podman inspect "$container" >/dev/null 2>&1; then
        fail "$container does not exist"
        return
    fi

    if ! status=$(podman inspect --format '{{.State.Status}}' "$container"); then
        fail "$container status could not be retrieved"
        return
    fi

    if [[ "$status" == "running" ]]; then
        pass "$container is running"
    else
        fail "$container status is $status"
    fi
}

check_container "$DB_CONTAINER"
check_container "$WEB_CONTAINER"

# Check PostgreSQL readiness
if podman exec "$DB_CONTAINER" \
    pg_isready -U app -d mydb >/dev/null 2>&1; then
    pass "PostgreSQL is accepting connections"
else
    fail "PostgreSQL is not accepting connections"
fi

# Check Flask health endpoint
if health_response=$(curl -fsS --connect-timeout 5 --max-time 10 \
    "$BASE_URL/health"); then
    pass "Flask health endpoint responded successfully"
    echo "       Response: $health_response"
else
    fail "Flask health endpoint failed"
fi

# Check items API
if curl -fsS --connect-timeout 5 --max-time 10 \
    -o /dev/null "$BASE_URL/items"; then
    pass "Items API endpoint responded successfully"
else
    fail "Items API endpoint failed"
fi

# Display summary
echo ""
echo "=================================="
echo " Validation Summary"
echo "=================================="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo "Validation completed with errors."
    exit 1
fi

echo "All validation checks passed!"
exit 0
