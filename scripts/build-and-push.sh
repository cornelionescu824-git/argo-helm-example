#!/bin/bash
# Build Spring Boot app and Docker image, load into kind cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KUBECONFIG_FILE="$PROJECT_ROOT/.kube/config"
CLUSTER_NAME="argo-helm-example"
IMAGE_NAME="simple-api:1.0.0"

echo "=== Building Simple API ==="

# Build with Maven
cd "$PROJECT_ROOT/simple-api"
mvn clean package -DskipTests

# Build Docker image
echo "Building Docker image $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" .

# Load into kind cluster (no registry needed for local)
echo "Loading image into kind cluster..."
export KUBECONFIG="$KUBECONFIG_FILE"
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

echo ""
echo "=== Build complete ==="
echo "Image $IMAGE_NAME is available in the kind cluster."
