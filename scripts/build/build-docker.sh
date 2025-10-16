#!/bin/bash
#
# Script: build-docker.sh
# Description: Build Docker image locally for testing
# Usage: ./scripts/build/build-docker.sh [TAG]
#

set -e

echo "========================================="
echo "Building Docker Image"
echo "========================================="

# Default tag
TAG="${1:-local}"
IMAGE_NAME="obo-app:${TAG}"

echo "Building image: $IMAGE_NAME"
echo "Using multi-stage Dockerfile..."

# Build Docker image
docker build \
    --build-arg BUILD_NUMBER="local-$(date +%Y%m%d-%H%M%S)" \
    --build-arg GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
    -t "$IMAGE_NAME" \
    .

echo ""
echo "✅ Docker image built successfully!"
echo "   Image: $IMAGE_NAME"
echo ""
echo "To run the container:"
echo "  docker run -p 8080:8080 \\"
echo "    -e DB_HOST=host.docker.internal \\"
echo "    -e DB_USERNAME=admin \\"
echo "    -e DB_PASSWORD=changeme \\"
echo "    -e DB_NAME=obo \\"
echo "    $IMAGE_NAME"
echo ""
echo "Or use docker-compose:"
echo "  docker-compose up"
echo ""

# Show image size
docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
