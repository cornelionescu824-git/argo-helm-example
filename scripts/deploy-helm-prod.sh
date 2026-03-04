#!/bin/bash
# Deploy Production environment via Helm (direct - no Argo CD)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KUBECONFIG_FILE="$PROJECT_ROOT/.kube/config"
HELM_CHART="$PROJECT_ROOT/helm-chart"
NAMESPACE="simple-api-prod"

export KUBECONFIG="${KUBECONFIG:-$KUBECONFIG_FILE}"

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
    echo "ERROR: Kubeconfig not found. Run ./scripts/setup-cluster.sh first."
    exit 1
fi

echo "=== Deploying Simple API (PROD) via Helm ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade simple-api "$HELM_CHART" \
    --install \
    --namespace "$NAMESPACE" \
    -f "$HELM_CHART/values.yaml" \
    -f "$HELM_CHART/values-prod.yaml" \
    --set image.repository=simple-api \
    --set image.tag=1.0.0 \
    --set image.pullPolicy=Never \
    --set monitor.image.repository=url-monitor \
    --set monitor.image.tag=1.0.0 \
    --set monitor.image.pullPolicy=Never \
    --set zookeeper.image.pullPolicy=Never \
    --wait \
    --timeout 120s

echo ""
echo "=== Prod deployment complete ==="
echo "  kubectl port-forward svc/simple-api 8081:8080 -n $NAMESPACE"
echo "  curl http://localhost:8081/hello"
echo "  curl http://localhost:8081/config/zk  # Zookeeper node: /prod/config"
echo "  Endpoint: prod.simple-api.local (add to /etc/hosts if using Ingress)"
echo ""
