#!/bin/bash
#
# Script: setup-env.sh
# Description: Setup environment configuration from template
# Usage: ./scripts/setup/setup-env.sh
#

set -e

echo "========================================="
echo "Setting up Environment Configuration"
echo "========================================="

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file"
        exit 0
    fi
fi

# Copy template
if [ ! -f .env.example ]; then
    echo "❌ Error: .env.example not found!"
    exit 1
fi

cp .env.example .env
echo "✅ Created .env from .env.example"

# Generate secure JWT secret
JWT_SECRET=$(openssl rand -base64 32)
sed -i.bak "s|PLEASE_CHANGE_THIS_TO_A_SECURE_RANDOM_256_BIT_KEY|$JWT_SECRET|g" .env
rm -f .env.bak
echo "✅ Generated secure JWT secret"

echo ""
echo "================================================"
echo "Environment file created: .env"
echo "================================================"
echo ""
echo "⚠️  IMPORTANT: Review and update the following:"
echo "  - DB_HOST (current: mysql)"
echo "  - DB_USERNAME (current: admin)"
echo "  - DB_PASSWORD (current: changeme)"
echo "  - DB_NAME (current: obo)"
echo ""
echo "For production deployment:"
echo "  - Use strong database credentials"
echo "  - Keep JWT_SECRET secure and never commit it"
echo "  - Update APP_PORT if needed (default: 8080)"
echo ""
