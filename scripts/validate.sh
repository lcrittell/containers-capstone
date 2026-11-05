#!/bin/bash

set -euo pipefail

#Define colors for later usage
green='\033[0;32m'
bold_red='\033[0;31m'


# Locate project files
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yaml"

# Application configuration
BASE_URL="${BASE_URL:-http://localhost:5001}"

# Track validation results
PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo -e "${green}[PASS] $1\033[0m"
    ((PASS_COUNT+=1))
}

fail() {
    echo -e "${bold_red}[FAIL] $1\033[0m"
    ((FAIL_COUNT+=1))
}

echo "=================================="
echo " Containers Capstone Validation"
echo "=================================="
echo ""

# Check Flask container
check_container() {
    local service="$1"
    local container_id
    local status

    if ! container_id=$(sudo docker compose -f "$COMPOSE_FILE" ps -q "$service"); then
        fail "$service container could not be checked"
        return
    fi

    if [[ -z "$container_id" ]]; then
        fail "$service container does not exist"
        return
    fi

    if ! status=$(sudo docker inspect -f '{{.State.Status}}' "$container_id"); then
        fail "$service container status could not be retrieved"
        return
    fi

    if [[ "$status" == "running" ]]; then
        pass "$service container is running"
    else
        fail "$service container status is $status"
    fi
}

check_container web
check_container db

# Check PostgreSQL readiness
if sudo docker compose -f "$COMPOSE_FILE" exec -T db \
    pg_isready -U app -d mydb >/dev/null 2>&1; then
    pass "PostgreSQL is accepting connections"
else
    fail "PostgreSQL is not accepting connections"
fi

# Check Flask health endpoint
if health_response=$(curl -fsS --connect-timeout 5 --max-time 10 "$BASE_URL/health"); then
    pass "Flask health endpoint responded successfully"
    echo "       Response: $health_response"
else
    fail "Flask health endpoint failed"
fi

# Check items API endpoint
if curl -fsS --connect-timeout 5 --max-time 10 \
    -o /dev/null "$BASE_URL/items"; then
    pass "Items API endpoint responded successfully"
else
    fail "Items API endpoint failed"
fi

# Display results
echo ""
echo "=================================="
echo " Validation Summary"
echo "=================================="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo -e "${bold_red}Validation completed with errors.\033[0m"
    exit 1
fi

echo -e "${green}All validation checks passed!\033[0m"
exit 0
