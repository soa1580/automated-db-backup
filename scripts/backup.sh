#!/bin/bash

set -u -o pipefail

# ============================================
# PostgreSQL Database Backup Script
# ============================================

# Configuration
CONTAINER_NAME="postgres-db"
DB_USER="admin"
DB_NAME="companydb"

BACKUP_DIR="$HOME/automated-db-backup/backups"
LOG_DIR="$HOME/automated-db-backup/logs"
LOG_FILE="$LOG_DIR/backup.log"
RETENTION_COUNT=7

S3_BUCKET=$(cd "$HOME/automated-db-backup/terraform" && terraform output -raw backup_bucket_name 2>/dev/null)
S3_PREFIX="postgresql-backups"

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
    echo " Backup Failed!"
    echo "==================================="
    echo "Error: $1"

    log_message "BACKUP_FAILED | $1"

    exit 1
}

cleanup_old_backups() {
    local backup_count

    backup_count=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${DB_NAME}_*.sql" | wc -l)

    if [ "$backup_count" -le "$RETENTION_COUNT" ]; then
        return 0
    fi

    find "$BACKUP_DIR" \
        -maxdepth 1 \
        -type f \
        -name "${DB_NAME}_*.sql" \
        -printf '%T@ %p\n' |
        sort -n |
        head -n -"$RETENTION_COUNT" |
        cut -d' ' -f2- |
        while IFS= read -r old_backup; do
            if [ -n "$old_backup" ]; then
                rm -f -- "$old_backup"
                log_message "BACKUP_DELETED | File: $old_backup"
            fi
        done
}

# ============================================
# Start
# ============================================

echo "==================================="
echo " PostgreSQL Backup Started"
echo "==================================="

# Create required directories
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Final and temporary backup filenames
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
TEMP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.tmp"

echo "Backup directory: $BACKUP_DIR"
echo "Database: $DB_NAME"
echo "Container: $CONTAINER_NAME"
echo

log_message "BACKUP_STARTED | Database: $DB_NAME | Container: $CONTAINER_NAME"

# ============================================
# Check Docker
# ============================================

if ! docker info >/dev/null 2>&1; then
    error_exit "Docker is not available. Make sure Docker is running and your user has permission to access it."
fi

# ============================================
# Check PostgreSQL container
# ============================================

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    error_exit "PostgreSQL container '$CONTAINER_NAME' is not running."
fi

# ============================================
# Create temporary backup
# ============================================

echo "Creating temporary backup..."

if docker exec "$CONTAINER_NAME" pg_dump \
    -U "$DB_USER" \
    "$DB_NAME" > "$TEMP_FILE"; then

    echo "pg_dump completed successfully."
else
    rm -f "$TEMP_FILE"
    error_exit "pg_dump failed."
fi

# ============================================
# Verify temporary backup
# ============================================

if [ ! -s "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
    error_exit "Temporary backup file is empty."
fi

# ============================================
# Move temporary file to final backup
# ============================================

if ! mv "$TEMP_FILE" "$BACKUP_FILE"; then
    rm -f "$TEMP_FILE"
    error_exit "Could not move temporary backup to final backup file."
fi

# ============================================
# Verify final backup
# ============================================

if [ ! -s "$BACKUP_FILE" ]; then
    rm -f "$BACKUP_FILE"
    error_exit "Final backup file is missing or empty."
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

# ============================================
# Upload backup to Amazon S3
# ============================================

echo
echo "Uploading backup to Amazon S3..."

S3_OBJECT="s3://${S3_BUCKET}/${S3_PREFIX}/$(basename "$BACKUP_FILE")"

if aws s3 cp "$BACKUP_FILE" "$S3_OBJECT"; then
    echo "S3 upload completed successfully."
else
    log_message "BACKUP_FAILED | S3 upload failed | File: $BACKUP_FILE"

    echo
    echo "==================================="
    echo " Backup Failed!"
    echo "==================================="
    echo "Error: S3 upload failed."
    echo "Local backup preserved:"
    echo "$BACKUP_FILE"

    exit 1
fi

# ============================================
# Verify S3 backup
# ============================================

echo "Verifying S3 backup..."

if aws s3api head-object \
    --bucket "$S3_BUCKET" \
    --key "${S3_PREFIX}/$(basename "$BACKUP_FILE")" \
    >/dev/null 2>&1; then

    echo "S3 backup verified successfully."
else
    log_message "BACKUP_FAILED | S3 verification failed | File: $BACKUP_FILE"

    echo
    echo "==================================="
    echo " Backup Failed!"
    echo "==================================="
    echo "Error: S3 backup verification failed."
    echo "Local backup preserved:"
    echo "$BACKUP_FILE"

    exit 1
fi

# ============================================
# Backup successful
# ============================================

echo
echo "==================================="
echo " Backup Successful!"
echo "==================================="
echo "Backup file:"
echo "$BACKUP_FILE"
echo "Backup size:"
echo "$BACKUP_SIZE"

log_message "BACKUP_SUCCESS | File: $BACKUP_FILE | Size: $BACKUP_SIZE"

cleanup_old_backups

exit 0
