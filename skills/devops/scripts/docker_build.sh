#!/bin/bash
# Docker Build and Push Script
# Usage: ./docker_build.sh <tag> [registry]

set -e

TAG=${1:-"latest"}
REGISTRY=${2:-""}
IMAGE_NAME="backend-app"

if [ -n "$REGISTRY" ]; then
    FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$TAG"
else
    FULL_IMAGE="$IMAGE_NAME:$TAG"
fi

echo "Building Docker image: $FULL_IMAGE"
echo "================================"

# Build image
docker build -t "$FULL_IMAGE" .

# Show image size
docker images "$FULL_IMAGE" --format "Size: {{.Size}}"

# Push if registry specified
if [ -n "$REGISTRY" ]; then
    echo "Pushing to registry..."
    docker push "$FULL_IMAGE"
fi

echo ""
echo "Build complete: $FULL_IMAGE"
