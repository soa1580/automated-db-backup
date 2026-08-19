#!/bin/bash

# ==========================================
# PostgreSQL Backup Health Check
# ==========================================

set -u

# Configuration
CONTAINER_NAME="postgres-db"
DB_USER="admin"
DB_NAME="companydb"

PROJECT_DIR="$HOME/automated-db-backup"
BACKUP_DIR="$PROJECT_DIR/backups"
LOG_DIR="$PROJECT_DIR/logs"
HEALTH_LOG="$LOG_DIR/health.log"

RETENTION_COUNT=7
MAX_BACKUP_AGE_HOURS=26

# ------------------------------------------
# Colors
# ------------------------------------------

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ------------------------------------------
# Counters
# ------------------------------------------

CHECKS_PASSED=0
CHECKS_FAILED=0

pass_check() {
    echo -e "${GREEN}[PASS]${NC} $1"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

fail_check() {
    echo -e "${RED}[FAIL]${NC} $1"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

# ------------------------------------------
# Header
# ------------------------------------------

echo "=========================================="
echo " PostgreSQL Backup Health Check"
echo "=========================================="
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# ------------------------------------------
# Check 1: Docker
# ------------------------------------------

if docker info >/dev/null 2>&1; then
    pass_check "Docker is available."
else
    fail_check "Docker is not available."
fi

# ------------------------------------------
# Check 2: PostgreSQL container
# ------------------------------------------

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    pass_check "PostgreSQL container '$CONTAINER_NAME' is running."
else
    fail_check "PostgreSQL container '$CONTAINER_NAME' is not running."
fi

# ------------------------------------------
# Check 3: Database connectivity
# ------------------------------------------

if docker exec "$CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" \
    >/dev/null 2>&1; then

    pass_check "Database '$DB_NAME' is accessible."

else
    fail_check "Database '$DB_NAME' is not accessible."
fi

# ------------------------------------------
# Check 4: Backup directory
# ------------------------------------------

if [ -d "$BACKUP_DIR" ]; then
    pass_check "Backup directory exists."
else
    fail_check "Backup directory does not exist."
fi

# ------------------------------------------
# Find latest backup
# ------------------------------------------

LATEST_BACKUP=$(find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    -name "${DB_NAME}_*.sql" \
    -printf '%T@ %p\n' 2>/dev/null |
    sort -n |
    tail -n 1 |
    cut -d' ' -f2-)

if [ -n "$LATEST_BACKUP" ] && [ -f "$LATEST_BACKUP" ]; then

    pass_check "Latest backup exists."

    # --------------------------------------
    # Check 5: Backup is not empty
    # --------------------------------------

    if [ -s "$LATEST_BACKUP" ]; then
        pass_check "Latest backup is not empty."
    else
        fail_check "Latest backup is empty."
    fi

    # --------------------------------------
    # Check 6: Backup age
    # --------------------------------------

    CURRENT_TIME=$(date +%s)
    BACKUP_TIME=$(stat -c %Y "$LATEST_BACKUP")
    BACKUP_AGE_SECONDS=$((CURRENT_TIME - BACKUP_TIME))
    BACKUP_AGE_HOURS=$((BACKUP_AGE_SECONDS / 3600))

    echo
    echo "Latest backup:"
    echo "$LATEST_BACKUP"
    echo "Backup age: ${BACKUP_AGE_HOURS} hour(s)"

    if [ "$BACKUP_AGE_HOURS" -le "$MAX_BACKUP_AGE_HOURS" ]; then
        pass_check "Latest backup is within ${MAX_BACKUP_AGE_HOURS}-hour threshold."
    else
        fail_check "Latest backup is older than ${MAX_BACKUP_AGE_HOURS} hours."
    fi

else
    fail_check "No backup files found."
fi

# ------------------------------------------
# Check 7: Backup count
# ------------------------------------------

BACKUP_COUNT=$(find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    -name "${DB_NAME}_*.sql" |
    wc -l)

echo
echo "Backup count: $BACKUP_COUNT"
echo "Retention limit: $RETENTION_COUNT"

if [ "$BACKUP_COUNT" -le "$RETENTION_COUNT" ]; then
    pass_check "Backup count is within retention limit."
else
    fail_check "Backup count exceeds retention limit."
fi

# ------------------------------------------
# Summary
# ------------------------------------------

echo
echo "=========================================="

if [ "$CHECKS_FAILED" -eq 0 ]; then

    echo -e " ${GREEN}SYSTEM HEALTHY${NC}"
    echo "Checks passed: $CHECKS_PASSED"
    echo "Checks failed: $CHECKS_FAILED"

    HEALTH_STATUS="HEALTHY"

else

    echo -e " ${RED}SYSTEM UNHEALTHY${NC}"
    echo "Checks passed: $CHECKS_PASSED"
    echo "Checks failed: $CHECKS_FAILED"

    HEALTH_STATUS="UNHEALTHY"
fi

echo "=========================================="

# ------------------------------------------
# Write health result to log
# ------------------------------------------

mkdir -p "$LOG_DIR"

echo "$(date '+%Y-%m-%d %H:%M:%S') | HEALTH_CHECK | Status: $HEALTH_STATUS | Passed: $CHECKS_PASSED | Failed: $CHECKS_FAILED | Backups: $BACKUP_COUNT" \
    >> "$HEALTH_LOG"

if [ "$CHECKS_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
