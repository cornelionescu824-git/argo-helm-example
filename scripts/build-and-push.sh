#!/bin/bash
# Build Spring Boot app + url-monitor sidecar, load both into kind cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KUBECONFIG_FILE="$PROJECT_ROOT/.kube/config"
CLUSTER_NAME="argo-helm-example"
API_IMAGE="simple-api:1.0.0"
MONITOR_IMAGE="url-monitor:1.0.0"

echo "=== Building Simple API ==="
cd "$PROJECT_ROOT/simple-api"
mvn clean package -DskipTests
echo "Building Docker image $API_IMAGE..."
docker build -t "$API_IMAGE" .

echo ""
echo "=== Building URL Monitor sidecar ==="
cd "$PROJECT_ROOT/monitor"
echo "Building Docker image $MONITOR_IMAGE..."
docker build -t "$MONITOR_IMAGE" .

echo ""
echo "=== Loading images into kind cluster ==="
export KUBECONFIG="$KUBECONFIG_FILE"
kind load docker-image "$API_IMAGE" --name "$CLUSTER_NAME"
kind load docker-image "$MONITOR_IMAGE" --name "$CLUSTER_NAME"

echo ""
echo "=== Build complete ==="
echo "Images loaded: $API_IMAGE, $MONITOR_IMAGE"
