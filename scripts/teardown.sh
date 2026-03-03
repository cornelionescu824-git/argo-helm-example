#!/bin/bash
# Teardown - delete the local cluster
# YOUR ~/.kube/config IS NEVER TOUCHED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLUSTER_NAME="argo-helm-example"

echo "=== Teardown Argo Helm Example ==="

# Unset KUBECONFIG if it points to our project (avoid errors)
if [[ "$KUBECONFIG" == *"argo-helm-example"* ]]; then
    unset KUBECONFIG
fi

kind delete cluster --name "$CLUSTER_NAME"

echo ""
echo "Cluster deleted. Your default kubectl config was not modified."
echo "To use Adobe/orchestration clusters, your kubectl will work as before."
