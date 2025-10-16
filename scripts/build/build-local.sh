#!/bin/bash
#
# Script: build-local.sh
# Description: Build application locally with Maven
# Usage: ./scripts/build/build-local.sh [--skip-tests]
#

set -e

echo "========================================="
echo "Building OBO Application (Local)"
echo "========================================="

# Parse arguments
SKIP_TESTS=false
if [[ "$1" == "--skip-tests" ]]; then
    SKIP_TESTS=true
fi

# Clean and build
echo "Cleaning previous build..."
./mvnw clean

if [ "$SKIP_TESTS" = true ]; then
    echo "Building without tests..."
    ./mvnw package -DskipTests
else
    echo "Building with tests..."
    ./mvnw package
fi

# Show build artifact
if [ -f target/obo-stadium-0.0.1-SNAPSHOT.jar ]; then
    FILE_SIZE=$(du -h target/obo-stadium-0.0.1-SNAPSHOT.jar | cut -f1)
    echo ""
    echo "✅ Build successful!"
    echo "   Artifact: target/obo-stadium-0.0.1-SNAPSHOT.jar"
    echo "   Size: $FILE_SIZE"
    echo ""
    echo "To run the application:"
    echo "  ./mvnw spring-boot:run"
    echo "  or"
    echo "  java -jar target/obo-stadium-0.0.1-SNAPSHOT.jar"
else
    echo "❌ Build failed! JAR file not found."
    exit 1
fi
