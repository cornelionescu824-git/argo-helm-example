#!/bin/bash
# Install Argo CD in the local kind cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KUBECONFIG_FILE="$PROJECT_ROOT/.kube/config"

export KUBECONFIG="${KUBECONFIG:-$KUBECONFIG_FILE}"

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
    echo "ERROR: Kubeconfig not found. Run ./scripts/setup-cluster.sh first."
    exit 1
fi

echo "=== Installing Argo CD ==="

# Create argocd namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=180s 2>/dev/null || true

# Get initial admin password
echo ""
echo "=== Argo CD installed ==="
echo ""
echo "To access Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server 8443:443 -n argocd"
echo "  Open https://localhost:8443"
echo ""
echo "Initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d
echo ""
echo ""
echo "Note: To use Argo CD with this example, you need to push the helm-chart to a Git repo"
echo "and update argo/application.yaml with your repo URL. See README.md for details."
