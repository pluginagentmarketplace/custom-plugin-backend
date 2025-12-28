#!/bin/bash
# PostgreSQL Database Backup Script
# Usage: ./backup_database.sh <database_name>

set -e

DB_NAME=${1:-"mydb"}
BACKUP_DIR=${BACKUP_DIR:-"./backups"}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

echo "Starting backup of database: $DB_NAME"
echo "Backup file: $BACKUP_FILE"

# Perform backup with compression
pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"

# Verify backup
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Backup completed successfully!"
    echo "File size: $SIZE"

    # Keep only last 7 backups
    cd "$BACKUP_DIR"
    ls -t ${DB_NAME}_*.sql.gz | tail -n +8 | xargs -r rm --
    echo "Old backups cleaned up (keeping last 7)"
else
    echo "Backup failed!"
    exit 1
fi
