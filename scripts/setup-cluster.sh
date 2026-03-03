#!/bin/bash
# Setup local Kubernetes cluster with ISOLATED kubeconfig
# YOUR DEFAULT ~/.kube/config IS NEVER MODIFIED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KUBECONFIG_DIR="$PROJECT_ROOT/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config"
CLUSTER_NAME="argo-helm-example"

echo "=== Argo Helm Example - Local Cluster Setup ==="
echo "Project root: $PROJECT_ROOT"
echo "Kubeconfig:   $KUBECONFIG_FILE (ISOLATED - does not touch ~/.kube/config)"
echo ""

# Create .kube directory
mkdir -p "$KUBECONFIG_DIR"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "ERROR: kind is not installed. Install with: brew install kind"
    exit 1
fi

# Delete existing cluster if it exists (idempotent)
kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true

# Create cluster with ISOLATED kubeconfig
echo "Creating kind cluster '$CLUSTER_NAME'..."
kind create cluster \
    --name "$CLUSTER_NAME" \
    --kubeconfig "$KUBECONFIG_FILE"

echo ""
echo "=== Cluster created successfully ==="
echo ""
echo "To use this cluster, run:"
echo "  export KUBECONFIG=$KUBECONFIG_FILE"
echo ""
echo "To switch back to your Adobe/orchestration clusters, run:"
echo "  unset KUBECONFIG"
echo "  # or: export KUBECONFIG=~/.kube/config"
echo ""
echo "Your default kubectl config was NOT modified."
