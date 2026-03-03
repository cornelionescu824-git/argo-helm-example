#!/bin/bash
# Deploy using Helm (direct deploy - no Argo CD)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KUBECONFIG_FILE="$PROJECT_ROOT/.kube/config"
HELM_CHART="$PROJECT_ROOT/helm-chart"
NAMESPACE="simple-api"

# Use isolated kubeconfig
export KUBECONFIG="${KUBECONFIG:-$KUBECONFIG_FILE}"

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
    echo "ERROR: Kubeconfig not found. Run ./scripts/setup-cluster.sh first."
    exit 1
fi

echo "=== Deploying Simple API via Helm ==="
echo "Using KUBECONFIG: $KUBECONFIG"
echo ""

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Helm upgrade (install if not exists)
helm upgrade simple-api "$HELM_CHART" \
    --install \
    --namespace "$NAMESPACE" \
    --set image.repository=simple-api \
    --set image.tag=1.0.0 \
    --set image.pullPolicy=Never \
    --set monitor.image.repository=url-monitor \
    --set monitor.image.tag=1.0.0 \
    --set monitor.image.pullPolicy=Never \
    --wait \
    --timeout 120s

echo ""
echo "=== Deployment complete ==="
echo ""
echo "To test:"
echo "  kubectl port-forward svc/simple-api 8080:8080 -n $NAMESPACE"
echo "  curl http://localhost:8080/hello"
echo ""
echo "To use this cluster's kubectl, ensure:"
echo "  export KUBECONFIG=$KUBECONFIG_FILE"
