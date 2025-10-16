#!/bin/bash
#
# Script: backup-db.sh
# Description: Backup MySQL database
# Usage: ./scripts/database/backup-db.sh [OUTPUT_DIR]
#

set -e

echo "========================================="
echo "Database Backup"
echo "========================================="

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Configuration
OUTPUT_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$OUTPUT_DIR/obo_db_backup_$TIMESTAMP.sql"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Database: $DB_NAME"
echo "Output: $BACKUP_FILE"
echo ""

# Check MySQL connection
if ! nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; then
    echo "❌ Error: Cannot connect to MySQL at $DB_HOST:$DB_PORT"
    exit 1
fi

# Perform backup
echo "Backing up database..."
mysqldump \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u "$DB_USERNAME" \
    -p"$DB_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "$DB_NAME" > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"
BACKUP_FILE="$BACKUP_FILE.gz"

FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo ""
echo "✅ Backup completed successfully!"
echo "   File: $BACKUP_FILE"
echo "   Size: $FILE_SIZE"
echo ""
echo "To restore this backup:"
echo "  gunzip -c $BACKUP_FILE | mysql -h \$DB_HOST -u \$DB_USERNAME -p \$DB_NAME"
echo ""
