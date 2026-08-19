#!/bin/bash

# ============================================
# PostgreSQL Database Restore Script
# ============================================

set -o pipefail

# ============================================
# Configuration
# ============================================

BACKUP_DIR="/home/phamac17/automated-db-backup/backups"
CONTAINER_NAME="postgres-db"
DB_USER="admin"

LOG_DIR="/home/phamac17/automated-db-backup/logs"
LOG_FILE="$LOG_DIR/restore.log"

# ============================================
# Functions
# ============================================

log_message() {
    mkdir -p "$LOG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

error_exit() {
    echo
    echo "==================================="
    echo " Restore Failed!"
    echo "==================================="
    echo "Error: $1"

    log_message "RESTORE_FAILED | $1"

    exit 1
}

# ============================================
# Validate arguments
# ============================================

BACKUP_FILE="$1"
TARGET_DB="$2"

if [ -z "$BACKUP_FILE" ]; then
    error_exit "No backup file specified."
fi

if [ -z "$TARGET_DB" ]; then
    error_exit "No target database specified."
fi

# ============================================
# Build full backup path
# ============================================

FULL_BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# ============================================
# Check backup file
# ============================================

if [ ! -f "$FULL_BACKUP_PATH" ]; then
    error_exit "Backup file does not exist: $FULL_BACKUP_PATH"
fi

if [ ! -s "$FULL_BACKUP_PATH" ]; then
    error_exit "Backup file is empty: $FULL_BACKUP_PATH"
fi

# ============================================
# Check PostgreSQL container
# ============================================

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    error_exit "PostgreSQL container '$CONTAINER_NAME' is not running."
fi

# ============================================
# Production Database Protection
# ============================================

if [ "$TARGET_DB" = "companydb" ]; then

    echo
    echo "WARNING: PRODUCTION DATABASE"
    echo "==================================="
    echo "You are about to restore into:"
    echo "Database: $TARGET_DB"
    echo
    echo "This operation may overwrite existing data."
    echo

    read -r -p "Type YES to continue: " CONFIRMATION

    if [ "$CONFIRMATION" != "YES" ]; then
        error_exit "Production restore cancelled by user."
    fi

    echo
    echo "Production restore confirmed."

    log_message "PRODUCTION_RESTORE_CONFIRMED | Backup: $BACKUP_FILE | Target: $TARGET_DB"
fi

# ============================================
# Display restore information
# ============================================

echo "==================================="
echo " PostgreSQL Restore Started"
echo "==================================="
echo "Backup file: $FULL_BACKUP_PATH"
echo "Target database: $TARGET_DB"
echo "Container: $CONTAINER_NAME"
echo

log_message "RESTORE_STARTED | Backup: $BACKUP_FILE | Target: $TARGET_DB"

# ============================================
# Restore database
# ============================================

echo "Restoring backup..."

if ! cat "$FULL_BACKUP_PATH" | docker exec -i "$CONTAINER_NAME" \
    psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$TARGET_DB"; then

    error_exit "PostgreSQL restore operation failed."
fi

# ============================================
# Verify restored data
# ============================================

echo
echo "Verifying restored database..."

EMPLOYEE_COUNT=$(docker exec "$CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$TARGET_DB" -tAc \
    "SELECT COUNT(*) FROM employees;" 2>/dev/null)

if [ $? -ne 0 ]; then
    error_exit "Could not verify the employees table."
fi

if [ -z "$EMPLOYEE_COUNT" ]; then
    error_exit "Verification returned no result."
fi

echo "Employees restored: $EMPLOYEE_COUNT"

if [ "$EMPLOYEE_COUNT" -eq 0 ]; then
    error_exit "Restore verification failed: employees table is empty."
fi

# ============================================
# Restore successful
# ============================================

echo
echo "==================================="
echo " Restore Successful!"
echo "==================================="
echo "Backup restored successfully."
echo "Target database: $TARGET_DB"
echo "Verified employee records: $EMPLOYEE_COUNT"

log_message "RESTORE_SUCCESS | Backup: $BACKUP_FILE | Target: $TARGET_DB | Employees: $EMPLOYEE_COUNT"

exit 0
