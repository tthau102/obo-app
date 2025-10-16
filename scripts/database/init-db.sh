#!/bin/bash
#
# Script: init-db.sh
# Description: Initialize MySQL database for local development
# Usage: ./scripts/database/init-db.sh
#

set -e

echo "========================================="
echo "Initializing Database"
echo "========================================="

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  .env file not found, using defaults"
    DB_HOST="localhost"
    DB_PORT="3306"
    DB_NAME="obo"
    DB_USERNAME="admin"
    DB_PASSWORD="changeme"
fi

echo "Database Host: $DB_HOST"
echo "Database Port: $DB_PORT"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USERNAME"
echo ""

# Check if MySQL is running
if ! nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; then
    echo "❌ Error: Cannot connect to MySQL at $DB_HOST:$DB_PORT"
    echo ""
    echo "To start MySQL with Docker Compose:"
    echo "  docker-compose up -d mysql"
    exit 1
fi

echo "✅ MySQL is running"
echo ""

# Create database if not exists
echo "Creating database '$DB_NAME' if not exists..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || {
    echo "⚠️  Note: If using Docker Compose, root password is set in docker-compose.yml"
}

echo "✅ Database '$DB_NAME' is ready"
echo ""
echo "Flyway will automatically run migrations on first application startup"
echo ""
echo "To start the application:"
echo "  ./mvnw spring-boot:run"
echo ""
